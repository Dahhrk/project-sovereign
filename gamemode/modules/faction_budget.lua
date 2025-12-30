--[[
    Faction Budget Module - Phase 2
    Shared faction resources and transaction tracking
]]--

-- Initialize faction budget data
GM.FactionBudgets = GM.FactionBudgets or {}

-- Initialize faction budgets
local function InitFactionBudgets()
    GAMEMODE:Log("Faction budget module initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitFactionBudgets", InitFactionBudgets)
end

-- Get faction budget data path
local function GetFactionBudgetPath()
    return "project_sovereign/faction_budgets.txt"
end

-- Save faction budgets
function GM:SaveFactionBudgets()
    if not SERVER then return false end
    
    local json = util.TableToJSON(self.FactionBudgets, true)
    if not json then
        self:ErrorLog("Failed to serialize faction budget data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write(GetFactionBudgetPath(), json)
    
    self:DebugLog("Saved faction budget data")
    return true
end

-- Load faction budgets
function GM:LoadFactionBudgets()
    if not SERVER then return false end
    
    local filePath = GetFactionBudgetPath()
    
    if not file.Exists(filePath, "DATA") then
        self:Log("No faction budget data found, initializing defaults")
        -- Initialize default budgets for all factions
        for factionName, _ in pairs(self.Factions or {}) do
            self.FactionBudgets[factionName] = {
                credits = 50000,
                transactions = {}
            }
        end
        self:SaveFactionBudgets()
        return true
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read faction budget data")
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse faction budget data")
        return false
    end
    
    self.FactionBudgets = data
    
    self:Log("Loaded faction budget data successfully")
    return true
end

-- Get faction budget
function GM:GetFactionCredits(faction)
    if not self.FactionBudgets[faction] then
        self.FactionBudgets[faction] = {
            credits = 50000,
            transactions = {}
        }
    end
    
    return self.FactionBudgets[faction].credits or 0
end

-- Set faction budget
function GM:SetFactionCredits(faction, amount)
    if not SERVER then return false end
    
    if not self.FactionBudgets[faction] then
        self.FactionBudgets[faction] = {
            credits = 0,
            transactions = {}
        }
    end
    
    amount = math.Clamp(amount, 0, self:GetConfig("MaxCredits") or 999999999)
    self.FactionBudgets[faction].credits = amount
    
    self:SaveFactionBudgets()
    return true
end

-- Add credits to faction budget
function GM:AddFactionCredits(faction, amount)
    if not SERVER then return false end
    
    local current = self:GetFactionCredits(faction)
    return self:SetFactionCredits(faction, current + amount)
end

-- Remove credits from faction budget
function GM:RemoveFactionCredits(faction, amount)
    if not SERVER then return false end
    
    local current = self:GetFactionCredits(faction)
    if current < amount then
        return false
    end
    
    return self:SetFactionCredits(faction, current - amount)
end

-- Check if faction can afford amount
function GM:FactionCanAfford(faction, amount)
    return self:GetFactionCredits(faction) >= amount
end

-- Record faction transaction
function GM:RecordFactionTransaction(faction, amount, type, description, playerSteamID, playerName)
    if not SERVER then return false end
    
    if not self.FactionBudgets[faction] then
        self.FactionBudgets[faction] = {
            credits = 50000,
            transactions = {}
        }
    end
    
    local transaction = {
        timestamp = os.time(),
        amount = amount,
        type = type, -- "deposit", "withdraw", "purchase", "income"
        description = description or "",
        player = playerSteamID or "SYSTEM",
        playerName = playerName or "System"
    }
    
    table.insert(self.FactionBudgets[faction].transactions, transaction)
    
    -- Keep only last 100 transactions
    if #self.FactionBudgets[faction].transactions > 100 then
        table.remove(self.FactionBudgets[faction].transactions, 1)
    end
    
    self:SaveFactionBudgets()
    return true
end

-- Faction transaction (player deposit/withdraw)
function GM:FactionTransaction(ply, amount, isDeposit)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local faction = self:GetPlayerFaction(ply)
    if not faction then
        return false, "You are not in a faction"
    end
    
    if not amount or amount <= 0 then
        return false, "Invalid amount"
    end
    
    if isDeposit then
        -- Player depositing to faction
        if not self:CanAfford(ply, amount) then
            return false, "Insufficient credits"
        end
        
        if self:RemovePlayerCredits(ply, amount) then
            self:AddFactionCredits(faction, amount)
            self:RecordFactionTransaction(faction, amount, "deposit", 
                "Player deposit", ply:SteamID(), ply:Nick())
            
            self:Log(string.format("%s deposited %d credits to %s faction budget",
                ply:Nick(), amount, faction))
            
            return true, "Deposit successful"
        end
    else
        -- Player withdrawing from faction
        if not self:FactionCanAfford(faction, amount) then
            return false, "Insufficient faction credits"
        end
        
        if self:RemoveFactionCredits(faction, amount) then
            self:AddPlayerCredits(ply, amount)
            self:RecordFactionTransaction(faction, -amount, "withdraw",
                "Player withdrawal", ply:SteamID(), ply:Nick())
            
            self:Log(string.format("%s withdrew %d credits from %s faction budget",
                ply:Nick(), amount, faction))
            
            return true, "Withdrawal successful"
        end
    end
    
    return false, "Transaction failed"
end

-- Commands

-- Faction balance command
GM:RegisterCommand("factionbalance", function(ply, args)
    local faction = GAMEMODE:GetPlayerFaction(ply)
    
    if not faction then
        GAMEMODE:Notify(ply, "You are not in a faction", NOTIFY_ERROR)
        return
    end
    
    local credits = GAMEMODE:GetFactionCredits(faction)
    GAMEMODE:Notify(ply, string.format("%s faction balance: %s", 
        faction, GAMEMODE:FormatCredits(credits)), NOTIFY_HINT)
end, false, "Check your faction's budget")

-- Faction deposit command
GM:RegisterCommand("factiondeposit", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /factiondeposit <amount>", NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    local success, msg = GAMEMODE:FactionTransaction(ply, amount, true)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Deposited %s to faction budget", 
            GAMEMODE:FormatCredits(amount)), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, false, "Deposit credits to your faction's budget")

-- Faction withdraw command (requires admin or high rank)
GM:RegisterCommand("factionwithdraw", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /factionwithdraw <amount>", NOTIFY_ERROR)
        return
    end
    
    -- Check if player has permission (admin or high rank)
    local faction = GAMEMODE:GetPlayerFaction(ply)
    local rank = GAMEMODE:GetPlayerRank(ply)
    
    -- Simple permission check - can be enhanced later
    local hasPermission = GAMEMODE:HasPermission(ply, "admin")
    
    if not hasPermission then
        GAMEMODE:Notify(ply, "You do not have permission to withdraw from faction budget", NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[1])
    if not amount or amount <= 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    local success, msg = GAMEMODE:FactionTransaction(ply, amount, false)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Withdrew %s from faction budget",
            GAMEMODE:FormatCredits(amount)), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, false, "Withdraw credits from your faction's budget (requires permission)")

-- View faction transactions (admin)
GM:RegisterCommand("factiontransactions", function(ply, args)
    local faction = GAMEMODE:GetPlayerFaction(ply)
    
    if not faction then
        GAMEMODE:Notify(ply, "You are not in a faction", NOTIFY_ERROR)
        return
    end
    
    local budgetData = GAMEMODE.FactionBudgets[faction]
    if not budgetData or not budgetData.transactions then
        GAMEMODE:Notify(ply, "No transaction history found", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint(string.format("=== %s FACTION TRANSACTIONS ===", faction))
    
    local count = math.min(10, #budgetData.transactions)
    for i = #budgetData.transactions, math.max(1, #budgetData.transactions - count + 1), -1 do
        local tx = budgetData.transactions[i]
        ply:ChatPrint(string.format("[%s] %s: %s%d by %s - %s",
            os.date("%Y-%m-%d %H:%M", tx.timestamp),
            tx.type,
            tx.amount >= 0 and "+" or "",
            tx.amount,
            tx.playerName,
            tx.description))
    end
    
    ply:ChatPrint("=============================")
end, false, "View your faction's recent transactions")

-- Admin: Set faction budget
GM:RegisterCommand("setfactionbudget", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /setfactionbudget <faction> <amount>", NOTIFY_ERROR)
        return
    end
    
    local faction = args[1]
    local amount = tonumber(args[2])
    
    if not amount or amount < 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    if GAMEMODE:SetFactionCredits(faction, amount) then
        GAMEMODE:Notify(ply, string.format("Set %s faction budget to %s",
            faction, GAMEMODE:FormatCredits(amount)), NOTIFY_GENERIC)
        GAMEMODE:Log(string.format("%s set %s faction budget to %d credits",
            ply:Nick(), faction, amount))
    else
        GAMEMODE:Notify(ply, "Failed to set faction budget", NOTIFY_ERROR)
    end
end, true, "Set a faction's budget (admin only)")

-- Load faction budgets on server init
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_LoadFactionBudgets", function()
        GAMEMODE:LoadFactionBudgets()
    end)
    
    -- Auto-save faction budgets periodically
    timer.Create("ProjectSovereign_FactionBudgetAutoSave", 300, 0, function()
        GAMEMODE:SaveFactionBudgets()
    end)
end
