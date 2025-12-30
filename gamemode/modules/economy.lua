--[[
    Economy Module
    Basic economy management system
]]--

-- Initialize economy module
local function InitEconomy()
    GAMEMODE:Log("Economy module initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitEconomy", InitEconomy)
end

-- Purchase item function
function GM:PurchaseItem(ply, itemName, itemCost)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not itemCost or itemCost <= 0 then
        return false, "Invalid item cost"
    end
    
    if not self:CanAfford(ply, itemCost) then
        return false, string.format("Insufficient credits. Cost: %s, You have: %s", 
            self:FormatCredits(itemCost), 
            self:FormatCredits(self:GetPlayerCredits(ply)))
    end
    
    if self:RemovePlayerCredits(ply, itemCost) then
        self:Log(string.format("%s purchased %s for %d credits", ply:Nick(), itemName, itemCost))
        return true, "Purchase successful"
    end
    
    return false, "Transaction failed"
end

-- Sell item function
function GM:SellItem(ply, itemName, itemValue)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not itemValue or itemValue <= 0 then
        return false, "Invalid item value"
    end
    
    if self:AddPlayerCredits(ply, itemValue) then
        self:Log(string.format("%s sold %s for %d credits", ply:Nick(), itemName, itemValue))
        return true, "Sale successful"
    end
    
    return false, "Transaction failed"
end

-- Economy transaction (generic)
function GM:EconomyTransaction(sender, receiver, amount, reason)
    if not self:IsValidPlayer(sender) then
        return false, "Invalid sender"
    end
    
    if not self:IsValidPlayer(receiver) then
        return false, "Invalid receiver"
    end
    
    if sender == receiver then
        return false, "Cannot transfer to yourself"
    end
    
    if not amount or amount <= 0 then
        return false, "Invalid amount"
    end
    
    if not self:CanAfford(sender, amount) then
        return false, "Insufficient credits"
    end
    
    if self:RemovePlayerCredits(sender, amount) and self:AddPlayerCredits(receiver, amount) then
        self:Log(string.format("Transaction: %s sent %d credits to %s (Reason: %s)", 
            sender:Nick(), amount, receiver:Nick(), reason or "None"))
        return true, "Transaction successful"
    end
    
    return false, "Transaction failed"
end

-- Check balance command
GM:RegisterCommand("balance", function(ply, args)
    local credits = GAMEMODE:GetPlayerCredits(ply)
    GAMEMODE:Notify(ply, string.format("Your balance: %s", GAMEMODE:FormatCredits(credits)), NOTIFY_HINT)
end, false, "Check your credit balance")

-- Check another player's balance (admin only)
GM:RegisterCommand("checkbalance", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /checkbalance <player>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local credits = GAMEMODE:GetPlayerCredits(target)
    GAMEMODE:Notify(ply, string.format("%s's balance: %s", target:Nick(), GAMEMODE:FormatCredits(credits)), NOTIFY_HINT)
end, true, "Check another player's credit balance")

-- Set credits command (admin only)
GM:RegisterCommand("setcredits", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /setcredits <player> <amount>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[2])
    if not amount or amount < 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:SetPlayerCredits(target, amount)
    
    GAMEMODE:Notify(ply, string.format("Set %s's credits to %s", target:Nick(), GAMEMODE:FormatCredits(amount)), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Your credits have been set to %s", GAMEMODE:FormatCredits(amount)), NOTIFY_HINT)
    GAMEMODE:Log(string.format("%s set %s's credits to %d", ply:Nick(), target:Nick(), amount))
end, true, "Set a player's credits")
