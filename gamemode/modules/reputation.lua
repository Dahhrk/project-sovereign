--[[
    Reputation System Module - Phase 2
    Per-faction reputation tracking with mission integration
]]--

-- Initialize player reputation
local function InitializePlayerReputation(ply)
    ply.Reputation = ply.Reputation or {}
    
    -- Initialize reputation for all factions
    if SERVER then
        for factionName, _ in pairs(GAMEMODE.Factions or {}) do
            if not ply.Reputation[factionName] then
                ply.Reputation[factionName] = 0
            end
        end
    end
end

-- Get reputation data path
local function GetReputationDataPath(steamID)
    local sanitized = string.gsub(steamID, ":", "_")
    return string.format("project_sovereign/reputation/%s.txt", sanitized)
end

-- Save player reputation
function GM:SavePlayerReputation(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    InitializePlayerReputation(ply)
    
    local steamID = ply:SteamID()
    local json = util.TableToJSON(ply.Reputation, true)
    
    if not json then
        self:ErrorLog("Failed to serialize reputation for " .. ply:Nick())
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/reputation")
    
    local filePath = GetReputationDataPath(steamID)
    file.Write(filePath, json)
    
    self:DebugLog(string.format("Saved reputation for %s", ply:Nick()))
    return true
end

-- Load player reputation
function GM:LoadPlayerReputation(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    local filePath = GetReputationDataPath(steamID)
    
    if not file.Exists(filePath, "DATA") then
        InitializePlayerReputation(ply)
        self:SavePlayerReputation(ply)
        return true
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read reputation for " .. ply:Nick())
        InitializePlayerReputation(ply)
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse reputation for " .. ply:Nick())
        InitializePlayerReputation(ply)
        return false
    end
    
    ply.Reputation = data
    InitializePlayerReputation(ply) -- Ensure all factions exist
    
    self:DebugLog(string.format("Loaded reputation for %s", ply:Nick()))
    return true
end

-- Get player reputation with faction
function GM:GetReputation(ply, faction)
    if not self:IsValidPlayer(ply) then return 0 end
    
    InitializePlayerReputation(ply)
    
    return ply.Reputation[faction] or 0
end

-- Set player reputation with faction
function GM:SetReputation(ply, faction, amount)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    InitializePlayerReputation(ply)
    
    -- Clamp reputation between -10000 and 10000
    amount = math.Clamp(amount, -10000, 10000)
    
    ply.Reputation[faction] = amount
    self:SavePlayerReputation(ply)
    
    return true
end

-- Add reputation
function GM:AddReputation(ply, faction, amount)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    local current = self:GetReputation(ply, faction)
    return self:SetReputation(ply, faction, current + amount)
end

-- Remove reputation
function GM:RemoveReputation(ply, faction, amount)
    if not SERVER then return false end
    
    return self:AddReputation(ply, faction, -amount)
end

-- Get reputation level/title
function GM:GetReputationLevel(reputation)
    if reputation >= 5000 then
        return "Legendary", Color(255, 215, 0)
    elseif reputation >= 2500 then
        return "Exalted", Color(138, 43, 226)
    elseif reputation >= 1000 then
        return "Revered", Color(0, 255, 0)
    elseif reputation >= 500 then
        return "Honored", Color(0, 200, 0)
    elseif reputation >= 100 then
        return "Friendly", Color(0, 150, 0)
    elseif reputation > -100 then
        return "Neutral", Color(200, 200, 0)
    elseif reputation > -500 then
        return "Unfriendly", Color(255, 100, 0)
    elseif reputation > -1000 then
        return "Hostile", Color(255, 50, 0)
    elseif reputation > -2500 then
        return "Hated", Color(255, 0, 0)
    else
        return "Despised", Color(139, 0, 0)
    end
end

-- Get all reputations for player
function GM:GetAllReputations(ply)
    if not self:IsValidPlayer(ply) then return {} end
    
    InitializePlayerReputation(ply)
    
    return ply.Reputation
end

-- Check if player can access content based on reputation
function GM:HasReputationAccess(ply, faction, requiredRep)
    local currentRep = self:GetReputation(ply, faction)
    return currentRep >= requiredRep
end

-- Reputation reward from mission
function GM:AwardMissionReputation(ply, faction, amount)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    self:AddReputation(ply, faction, amount)
    
    local newRep = self:GetReputation(ply, faction)
    local level, color = self:GetReputationLevel(newRep)
    
    self:Notify(ply, string.format("Gained %d reputation with %s (Total: %d - %s)",
        amount, faction, newRep, level), NOTIFY_HINT)
    
    self:Log(string.format("%s gained %d reputation with %s (Total: %d)",
        ply:Nick(), amount, faction, newRep))
    
    return true
end

-- Commands

-- Check reputation command
GM:RegisterCommand("reputation", function(ply, args)
    local reputations = GAMEMODE:GetAllReputations(ply)
    
    ply:ChatPrint("=== YOUR REPUTATION ===")
    
    for faction, rep in pairs(reputations) do
        local level, color = GAMEMODE:GetReputationLevel(rep)
        ply:ChatPrint(string.format("%s: %d (%s)", faction, rep, level))
    end
    
    ply:ChatPrint("======================")
end, false, "View your reputation with all factions")

-- Check reputation with specific faction
GM:RegisterCommand("reputationcheck", function(ply, args)
    if #args < 1 then
        -- Show all if no faction specified
        local cmd = GAMEMODE.Commands["reputation"]
        if cmd then
            cmd.callback(ply, {})
        end
        return
    end
    
    local faction = args[1]
    local rep = GAMEMODE:GetReputation(ply, faction)
    
    if not GAMEMODE.Factions or not GAMEMODE.Factions[faction] then
        GAMEMODE:Notify(ply, "Invalid faction: " .. faction, NOTIFY_ERROR)
        return
    end
    
    local level, color = GAMEMODE:GetReputationLevel(rep)
    
    ply:ChatPrint(string.format("=== %s REPUTATION ===", faction))
    ply:ChatPrint(string.format("Score: %d", rep))
    ply:ChatPrint(string.format("Level: %s", level))
    
    -- Show next level threshold
    local nextThresholds = {
        {-10000, "Despised"},
        {-2500, "Hated"},
        {-1000, "Hostile"},
        {-500, "Unfriendly"},
        {-100, "Neutral"},
        {100, "Friendly"},
        {500, "Honored"},
        {1000, "Revered"},
        {2500, "Exalted"},
        {5000, "Legendary"}
    }
    
    for i, threshold in ipairs(nextThresholds) do
        if rep < threshold[1] then
            local needed = threshold[1] - rep
            ply:ChatPrint(string.format("Next Level: %s (Need %d more rep)", threshold[2], needed))
            break
        end
    end
    
    ply:ChatPrint("===================")
end, false, "Check your reputation with a specific faction")

-- Admin: Set player reputation
GM:RegisterCommand("setreputation", function(ply, args)
    if #args < 3 then
        GAMEMODE:Notify(ply, "Usage: /setreputation <player> <faction> <amount>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = args[2]
    if not GAMEMODE.Factions or not GAMEMODE.Factions[faction] then
        GAMEMODE:Notify(ply, "Invalid faction: " .. faction, NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[3])
    if not amount then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:SetReputation(target, faction, amount)
    
    local level, color = GAMEMODE:GetReputationLevel(amount)
    
    GAMEMODE:Notify(ply, string.format("Set %s's %s reputation to %d (%s)",
        target:Nick(), faction, amount, level), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Your %s reputation has been set to %d (%s)",
        faction, amount, level), NOTIFY_HINT)
    GAMEMODE:Log(string.format("%s set %s's %s reputation to %d",
        ply:Nick(), target:Nick(), faction, amount))
end, true, "Set a player's reputation with a faction (admin only)")

-- Admin: Add reputation to player
GM:RegisterCommand("addreputation", function(ply, args)
    if #args < 3 then
        GAMEMODE:Notify(ply, "Usage: /addreputation <player> <faction> <amount>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = args[2]
    if not GAMEMODE.Factions or not GAMEMODE.Factions[faction] then
        GAMEMODE:Notify(ply, "Invalid faction: " .. faction, NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[3])
    if not amount then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:AddReputation(target, faction, amount)
    
    local newRep = GAMEMODE:GetReputation(target, faction)
    local level, color = GAMEMODE:GetReputationLevel(newRep)
    
    GAMEMODE:Notify(ply, string.format("Added %d reputation with %s to %s (Total: %d - %s)",
        amount, faction, target:Nick(), newRep, level), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Gained %d reputation with %s (Total: %d - %s)",
        amount, faction, newRep, level), NOTIFY_HINT)
    GAMEMODE:Log(string.format("%s added %d %s reputation to %s",
        ply:Nick(), amount, faction, target:Nick()))
end, true, "Add reputation to a player (admin only)")

-- Load reputation on player spawn
if SERVER then
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_LoadReputation", function(ply)
        GAMEMODE:LoadPlayerReputation(ply)
    end)
    
    -- Save reputation on disconnect
    hook.Add("PlayerDisconnected", "ProjectSovereign_SaveReputation", function(ply)
        GAMEMODE:SavePlayerReputation(ply)
    end)
    
    -- Save all reputations periodically
    timer.Create("ProjectSovereign_ReputationAutoSave", 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            GAMEMODE:SavePlayerReputation(ply)
        end
    end)
end
