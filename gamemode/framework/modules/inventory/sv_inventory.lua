--[[
    Server Inventory System - Phase 2
    Manages player inventories with weight-based limits
]]--

if not SERVER then return end

-- Initialize player inventory
local function InitializePlayerInventory(ply)
    ply.Inventory = ply.Inventory or {
        items = {},
        maxWeight = 100, -- Default max weight
        currentWeight = 0
    }
end

-- Get inventory data path
local function GetInventoryDataPath(steamID)
    local sanitized = string.gsub(steamID, ":", "_")
    return string.format("project_sovereign/inventories/%s.txt", sanitized)
end

-- Save player inventory
function GM:SavePlayerInventory(ply)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    InitializePlayerInventory(ply)
    
    local steamID = ply:SteamID()
    local data = {
        items = ply.Inventory.items,
        maxWeight = ply.Inventory.maxWeight,
        currentWeight = ply.Inventory.currentWeight
    }
    
    local json = util.TableToJSON(data, true)
    if not json then
        self:ErrorLog("Failed to serialize inventory for " .. ply:Nick())
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/inventories")
    
    local filePath = GetInventoryDataPath(steamID)
    file.Write(filePath, json)
    
    self:DebugLog(string.format("Saved inventory for %s", ply:Nick()))
    return true
end

-- Load player inventory
function GM:LoadPlayerInventory(ply)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    local filePath = GetInventoryDataPath(steamID)
    
    if not file.Exists(filePath, "DATA") then
        InitializePlayerInventory(ply)
        return true
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read inventory for " .. ply:Nick())
        InitializePlayerInventory(ply)
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse inventory for " .. ply:Nick())
        InitializePlayerInventory(ply)
        return false
    end
    
    ply.Inventory = {
        items = data.items or {},
        maxWeight = data.maxWeight or 100,
        currentWeight = data.currentWeight or 0
    }
    
    -- Recalculate weight to ensure accuracy
    self:RecalculateInventoryWeight(ply)
    
    self:DebugLog(string.format("Loaded inventory for %s", ply:Nick()))
    return true
end

-- Calculate item weight
function GM:GetItemWeight(itemID, quantity)
    local item = self:GetItem(itemID)
    if not item then return 0 end
    
    return item.weight * quantity
end

-- Calculate current inventory weight
function GM:RecalculateInventoryWeight(ply)
    if not self:IsValidPlayer(ply) then return 0 end
    
    InitializePlayerInventory(ply)
    
    local totalWeight = 0
    for itemID, quantity in pairs(ply.Inventory.items) do
        totalWeight = totalWeight + self:GetItemWeight(itemID, quantity)
    end
    
    ply.Inventory.currentWeight = totalWeight
    return totalWeight
end

-- Check if player has inventory space
function GM:HasInventorySpace(ply, itemID, quantity)
    if not self:IsValidPlayer(ply) then return false end
    
    InitializePlayerInventory(ply)
    
    local itemWeight = self:GetItemWeight(itemID, quantity)
    local newWeight = ply.Inventory.currentWeight + itemWeight
    
    return newWeight <= ply.Inventory.maxWeight
end

-- Add item to inventory
function GM:AddInventoryItem(ply, itemID, quantity)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local item = self:GetItem(itemID)
    if not item then
        return false, "Invalid item"
    end
    
    quantity = quantity or 1
    if quantity <= 0 then
        return false, "Invalid quantity"
    end
    
    InitializePlayerInventory(ply)
    
    -- Check weight limit
    if not self:HasInventorySpace(ply, itemID, quantity) then
        return false, "Inventory weight limit exceeded"
    end
    
    -- Check stack limit
    local currentAmount = ply.Inventory.items[itemID] or 0
    local newAmount = currentAmount + quantity
    
    if newAmount > item.maxStack then
        return false, string.format("Stack limit exceeded (max: %d)", item.maxStack)
    end
    
    ply.Inventory.items[itemID] = newAmount
    self:RecalculateInventoryWeight(ply)
    self:SavePlayerInventory(ply)
    
    self:Log(string.format("%s received %dx %s", ply:Nick(), quantity, item.name))
    
    return true, quantity
end

-- Remove item from inventory
function GM:RemoveInventoryItem(ply, itemID, quantity)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    quantity = quantity or 1
    if quantity <= 0 then
        return false, "Invalid quantity"
    end
    
    InitializePlayerInventory(ply)
    
    local currentAmount = ply.Inventory.items[itemID] or 0
    if currentAmount < quantity then
        return false, "Insufficient items"
    end
    
    local newAmount = currentAmount - quantity
    if newAmount <= 0 then
        ply.Inventory.items[itemID] = nil
    else
        ply.Inventory.items[itemID] = newAmount
    end
    
    self:RecalculateInventoryWeight(ply)
    self:SavePlayerInventory(ply)
    
    return true, quantity
end

-- Has item in inventory
function GM:HasInventoryItem(ply, itemID, quantity)
    if not self:IsValidPlayer(ply) then return false end
    
    InitializePlayerInventory(ply)
    
    quantity = quantity or 1
    local currentAmount = ply.Inventory.items[itemID] or 0
    
    return currentAmount >= quantity
end

-- Get item quantity
function GM:GetInventoryItemCount(ply, itemID)
    if not self:IsValidPlayer(ply) then return 0 end
    
    InitializePlayerInventory(ply)
    
    return ply.Inventory.items[itemID] or 0
end

-- Get inventory
function GM:GetPlayerInventory(ply)
    if not self:IsValidPlayer(ply) then return {} end
    
    InitializePlayerInventory(ply)
    
    return ply.Inventory
end

-- Set max inventory weight
function GM:SetInventoryMaxWeight(ply, weight)
    if not self:IsValidPlayer(ply) then return false end
    
    InitializePlayerInventory(ply)
    
    ply.Inventory.maxWeight = math.max(1, weight)
    self:SavePlayerInventory(ply)
    
    return true
end

-- Commands

-- Inventory command
GM:RegisterCommand("inventory", function(ply, args)
    local inventory = GAMEMODE:GetPlayerInventory(ply)
    
    if table.Count(inventory.items) == 0 then
        GAMEMODE:Notify(ply, "Your inventory is empty", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== YOUR INVENTORY ===")
    ply:ChatPrint(string.format("Weight: %.1f / %.1f kg", inventory.currentWeight, inventory.maxWeight))
    ply:ChatPrint("Items:")
    
    for itemID, quantity in pairs(inventory.items) do
        local item = GAMEMODE:GetItem(itemID)
        if item then
            local weight = GAMEMODE:GetItemWeight(itemID, quantity)
            ply:ChatPrint(string.format("  %dx %s (%.1f kg)", quantity, item.name, weight))
        end
    end
    
    ply:ChatPrint("=====================")
end, false, "View your inventory")

-- Give item command
GM:RegisterCommand("giveitem", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /giveitem <player> <item> [quantity]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local itemID = args[2]
    local item = GAMEMODE:GetItem(itemID)
    if not item then
        GAMEMODE:Notify(ply, "Invalid item: " .. itemID, NOTIFY_ERROR)
        return
    end
    
    local quantity = 1
    if #args > 2 then
        quantity = tonumber(args[3]) or 1
    end
    
    -- Check if sender has the item (unless admin)
    local isAdmin = GAMEMODE:HasPermission(ply, "admin")
    
    if not isAdmin then
        if not GAMEMODE:HasInventoryItem(ply, itemID, quantity) then
            GAMEMODE:Notify(ply, "You don't have enough of that item", NOTIFY_ERROR)
            return
        end
    end
    
    -- Give to target
    local success, msg = GAMEMODE:AddInventoryItem(target, itemID, quantity)
    
    if success then
        -- Remove from sender (unless admin)
        if not isAdmin then
            GAMEMODE:RemoveInventoryItem(ply, itemID, quantity)
        end
        
        GAMEMODE:Notify(ply, string.format("Gave %dx %s to %s", quantity, item.name, target:Nick()), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("Received %dx %s from %s", quantity, item.name, ply:Nick()), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s gave %dx %s to %s", ply:Nick(), quantity, item.name, target:Nick()))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, false, "Give an item to another player")

-- Admin: Add item to player
GM:RegisterCommand("additem", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /additem <player> <item> [quantity]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local itemID = args[2]
    local item = GAMEMODE:GetItem(itemID)
    if not item then
        GAMEMODE:Notify(ply, "Invalid item: " .. itemID, NOTIFY_ERROR)
        return
    end
    
    local quantity = 1
    if #args > 2 then
        quantity = tonumber(args[3]) or 1
    end
    
    local success, msg = GAMEMODE:AddInventoryItem(target, itemID, quantity)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Added %dx %s to %s's inventory", quantity, item.name, target:Nick()), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("Received %dx %s", quantity, item.name), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s added %dx %s to %s's inventory", ply:Nick(), quantity, item.name, target:Nick()))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Add an item to a player's inventory (admin only)")

-- Admin: Remove item from player
GM:RegisterCommand("removeitem", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /removeitem <player> <item> [quantity]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local itemID = args[2]
    local item = GAMEMODE:GetItem(itemID)
    if not item then
        GAMEMODE:Notify(ply, "Invalid item: " .. itemID, NOTIFY_ERROR)
        return
    end
    
    local quantity = 1
    if #args > 2 then
        quantity = tonumber(args[3]) or 1
    end
    
    local success, msg = GAMEMODE:RemoveInventoryItem(target, itemID, quantity)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Removed %dx %s from %s's inventory", quantity, item.name, target:Nick()), NOTIFY_GENERIC)
        GAMEMODE:Log(string.format("%s removed %dx %s from %s's inventory", ply:Nick(), quantity, item.name, target:Nick()))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Remove an item from a player's inventory (admin only)")

-- List all items command
GM:RegisterCommand("listitems", function(ply, args)
    local items = GAMEMODE:GetAllItems()
    
    ply:ChatPrint("=== ALL ITEMS ===")
    for itemID, item in pairs(items) do
        ply:ChatPrint(string.format("%s | %s - %s", itemID, item.name, item.description))
        ply:ChatPrint(string.format("  Weight: %.1f kg | Stack: %d | Value: %d credits",
            item.weight, item.maxStack, item.sellValue))
    end
    ply:ChatPrint("=================")
end, false, "List all available items")

-- Load inventory on player spawn
hook.Add("PlayerInitialSpawn", "ProjectSovereign_LoadInventory", function(ply)
    GAMEMODE:LoadPlayerInventory(ply)
end)

-- Save inventory on disconnect
hook.Add("PlayerDisconnected", "ProjectSovereign_SaveInventory", function(ply)
    GAMEMODE:SavePlayerInventory(ply)
end)
