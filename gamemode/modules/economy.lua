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

-- Tax system
GM.EconomyTax = GM.EconomyTax or {
    TransactionTaxRate = 0.05, -- 5% transaction tax
    PurchaseTaxRate = 0.10, -- 10% purchase tax
    TaxEnabled = true
}

-- Calculate tax on amount
function GM:CalculateTax(amount, taxRate)
    if not self.EconomyTax.TaxEnabled then
        return 0
    end
    
    taxRate = taxRate or self.EconomyTax.TransactionTaxRate
    return math.floor(amount * taxRate)
end

-- Apply transaction tax
function GM:ApplyTransactionTax(amount)
    return self:CalculateTax(amount, self.EconomyTax.TransactionTaxRate)
end

-- Apply purchase tax
function GM:ApplyPurchaseTax(amount)
    return self:CalculateTax(amount, self.EconomyTax.PurchaseTaxRate)
end

-- Set tax rates (admin only)
function GM:SetTaxRate(taxType, rate)
    if not SERVER then return false end
    
    rate = math.Clamp(rate, 0, 1)
    
    if taxType == "transaction" then
        self.EconomyTax.TransactionTaxRate = rate
    elseif taxType == "purchase" then
        self.EconomyTax.PurchaseTaxRate = rate
    else
        return false
    end
    
    return true
end

-- Enable/disable taxes
function GM:SetTaxEnabled(enabled)
    if not SERVER then return false end
    
    self.EconomyTax.TaxEnabled = enabled
    return true
end

-- Purchase item function
function GM:PurchaseItem(ply, itemName, itemCost)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not itemCost or itemCost <= 0 then
        return false, "Invalid item cost"
    end
    
    -- Calculate total cost with tax
    local tax = self:ApplyPurchaseTax(itemCost)
    local totalCost = itemCost + tax
    
    if not self:CanAfford(ply, totalCost) then
        return false, string.format("Insufficient credits. Cost: %s + Tax: %s = %s, You have: %s", 
            self:FormatCredits(itemCost),
            self:FormatCredits(tax),
            self:FormatCredits(totalCost), 
            self:FormatCredits(self:GetPlayerCredits(ply)))
    end
    
    if self:RemovePlayerCredits(ply, totalCost) then
        self:Log(string.format("%s purchased %s for %d credits (tax: %d)", 
            ply:Nick(), itemName, itemCost, tax))
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
    
    -- Calculate tax
    local tax = self:ApplyTransactionTax(amount)
    local totalCost = amount + tax
    
    if not self:CanAfford(sender, totalCost) then
        return false, string.format("Insufficient credits (need %s including %s tax)", 
            self:FormatCredits(totalCost), self:FormatCredits(tax))
    end
    
    if self:RemovePlayerCredits(sender, totalCost) and self:AddPlayerCredits(receiver, amount) then
        self:Log(string.format("Transaction: %s sent %d credits to %s (Tax: %d, Reason: %s)", 
            sender:Nick(), amount, receiver:Nick(), tax, reason or "None"))
        return true, string.format("Transaction successful (tax: %s)", self:FormatCredits(tax))
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

-- Set tax rate command (admin only)
GM:RegisterCommand("settaxrate", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /settaxrate <type> <rate>", NOTIFY_ERROR)
        GAMEMODE:Notify(ply, "Types: transaction, purchase", NOTIFY_HINT)
        GAMEMODE:Notify(ply, "Rate: 0.0 to 1.0 (e.g., 0.05 = 5%)", NOTIFY_HINT)
        return
    end
    
    local taxType = string.lower(args[1])
    local rate = tonumber(args[2])
    
    if not rate or rate < 0 or rate > 1 then
        GAMEMODE:Notify(ply, "Invalid rate (must be between 0.0 and 1.0)", NOTIFY_ERROR)
        return
    end
    
    if GAMEMODE:SetTaxRate(taxType, rate) then
        GAMEMODE:Notify(ply, string.format("Set %s tax rate to %.1f%%", taxType, rate * 100), NOTIFY_GENERIC)
        GAMEMODE:Log(string.format("%s set %s tax rate to %.2f", ply:Nick(), taxType, rate))
    else
        GAMEMODE:Notify(ply, "Invalid tax type (use: transaction or purchase)", NOTIFY_ERROR)
    end
end, true, "Set economy tax rates")

-- View tax rates command
GM:RegisterCommand("taxrates", function(ply, args)
    ply:ChatPrint("=== TAX RATES ===")
    ply:ChatPrint(string.format("Transaction Tax: %.1f%%", GAMEMODE.EconomyTax.TransactionTaxRate * 100))
    ply:ChatPrint(string.format("Purchase Tax: %.1f%%", GAMEMODE.EconomyTax.PurchaseTaxRate * 100))
    ply:ChatPrint(string.format("Taxes Enabled: %s", GAMEMODE.EconomyTax.TaxEnabled and "Yes" or "No"))
    ply:ChatPrint("=================")
end, false, "View current tax rates")

-- Toggle taxes command (admin only)
GM:RegisterCommand("toggletaxes", function(ply, args)
    local newState = not GAMEMODE.EconomyTax.TaxEnabled
    GAMEMODE:SetTaxEnabled(newState)
    
    GAMEMODE:Notify(ply, string.format("Taxes %s", newState and "enabled" or "disabled"), NOTIFY_GENERIC)
    GAMEMODE:NotifyAll(string.format("Economy taxes have been %s", newState and "enabled" or "disabled"), NOTIFY_HINT)
    GAMEMODE:Log(string.format("%s %s economy taxes", ply:Nick(), newState and "enabled" or "disabled"))
end, true, "Toggle economy taxes on/off")

