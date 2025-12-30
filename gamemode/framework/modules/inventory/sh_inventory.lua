--[[
    Inventory System - Phase 2
    Shared inventory functions and item definitions
]]--

-- Item definitions
GM.Items = GM.Items or {}

-- Define item
function GM:DefineItem(itemID, data)
    self.Items[itemID] = {
        id = itemID,
        name = data.name or itemID,
        description = data.description or "",
        weight = data.weight or 1,
        maxStack = data.maxStack or 1,
        category = data.category or "misc",
        rarity = data.rarity or "common",
        sellValue = data.sellValue or 0,
        buyValue = data.buyValue or 0,
        usable = data.usable or false,
        onUse = data.onUse or nil,
        factionRestricted = data.factionRestricted or nil
    }
end

-- Get item data
function GM:GetItem(itemID)
    return self.Items[itemID]
end

-- Get all items
function GM:GetAllItems()
    return self.Items
end

-- Register default items
GM:DefineItem("medkit", {
    name = "Medkit",
    description = "Restores 50 health",
    weight = 2,
    maxStack = 5,
    category = "medical",
    rarity = "uncommon",
    sellValue = 100,
    buyValue = 250,
    usable = true
})

GM:DefineItem("ammo_pack", {
    name = "Ammo Pack",
    description = "Ammunition for weapons",
    weight = 3,
    maxStack = 10,
    category = "ammunition",
    rarity = "common",
    sellValue = 50,
    buyValue = 100,
    usable = true
})

GM:DefineItem("ration", {
    name = "Ration Pack",
    description = "Basic food ration",
    weight = 1,
    maxStack = 20,
    category = "consumable",
    rarity = "common",
    sellValue = 25,
    buyValue = 50,
    usable = true
})

GM:DefineItem("scrap_metal", {
    name = "Scrap Metal",
    description = "Raw materials for crafting",
    weight = 5,
    maxStack = 50,
    category = "resource",
    rarity = "common",
    sellValue = 10,
    buyValue = 20,
    usable = false
})

GM:DefineItem("electronics", {
    name = "Electronics",
    description = "Electronic components",
    weight = 1,
    maxStack = 20,
    category = "resource",
    rarity = "uncommon",
    sellValue = 50,
    buyValue = 100,
    usable = false
})

GM:DefineItem("weapon_parts", {
    name = "Weapon Parts",
    description = "Components for weapon crafting",
    weight = 3,
    maxStack = 10,
    category = "resource",
    rarity = "rare",
    sellValue = 200,
    buyValue = 400,
    usable = false
})

GM:DefineItem("credits_chip", {
    name = "Credit Chip",
    description = "Contains 1000 credits",
    weight = 0.1,
    maxStack = 10,
    category = "currency",
    rarity = "rare",
    sellValue = 1000,
    buyValue = 1000,
    usable = true
})

-- Print loaded items
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_ItemsInit", function()
        GAMEMODE:Log(string.format("Loaded %d item definitions", table.Count(GAMEMODE.Items)))
    end)
end
