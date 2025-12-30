--[[
    Crafting System Module - Phase 2
    Resource combination and item crafting with faction-specific recipes
]]--

-- Initialize crafting data
GM.CraftingRecipes = GM.CraftingRecipes or {}

-- Define a crafting recipe
function GM:DefineRecipe(recipeID, data)
    self.CraftingRecipes[recipeID] = {
        id = recipeID,
        name = data.name or recipeID,
        description = data.description or "",
        ingredients = data.ingredients or {},
        result = data.result,
        resultQuantity = data.resultQuantity or 1,
        craftTime = data.craftTime or 5,
        requiredFaction = data.requiredFaction or nil,
        requiredRank = data.requiredRank or nil,
        category = data.category or "general"
    }
end

-- Get recipe
function GM:GetRecipe(recipeID)
    return self.CraftingRecipes[recipeID]
end

-- Get all recipes
function GM:GetAllRecipes()
    return self.CraftingRecipes
end

-- Get recipes for faction
function GM:GetFactionRecipes(faction)
    local recipes = {}
    
    for recipeID, recipe in pairs(self.CraftingRecipes) do
        if not recipe.requiredFaction or recipe.requiredFaction == faction then
            recipes[recipeID] = recipe
        end
    end
    
    return recipes
end

-- Register default recipes

-- General recipes
GM:DefineRecipe("craft_medkit", {
    name = "Craft Medkit",
    description = "Create a medkit from electronics and scrap",
    ingredients = {
        electronics = 2,
        scrap_metal = 3
    },
    result = "medkit",
    resultQuantity = 1,
    craftTime = 10,
    category = "medical"
})

GM:DefineRecipe("craft_ammo", {
    name = "Craft Ammo Pack",
    description = "Create ammunition from scrap and weapon parts",
    ingredients = {
        scrap_metal = 5,
        weapon_parts = 1
    },
    result = "ammo_pack",
    resultQuantity = 2,
    craftTime = 8,
    category = "ammunition"
})

-- Republic-specific recipes
GM:DefineRecipe("republic_advanced_medkit", {
    name = "Advanced Medkit",
    description = "Republic-grade medical supplies",
    ingredients = {
        medkit = 2,
        electronics = 5
    },
    result = "medkit",
    resultQuantity = 4,
    craftTime = 15,
    requiredFaction = "Republic",
    category = "medical"
})

-- CIS-specific recipes
GM:DefineRecipe("cis_droid_parts", {
    name = "Droid Components",
    description = "Craft droid parts for repairs",
    ingredients = {
        electronics = 10,
        scrap_metal = 20,
        weapon_parts = 2
    },
    result = "electronics",
    resultQuantity = 15,
    craftTime = 20,
    requiredFaction = "CIS",
    category = "resource"
})

-- Jedi-specific recipes
GM:DefineRecipe("jedi_meditation_focus", {
    name = "Meditation Focus",
    description = "Craft a meditation aid",
    ingredients = {
        electronics = 3
    },
    result = "medkit",
    resultQuantity = 2,
    craftTime = 10,
    requiredFaction = "Jedi",
    category = "medical"
})

-- Sith-specific recipes
GM:DefineRecipe("sith_dark_infusion", {
    name = "Dark Infusion",
    description = "Create enhanced supplies through dark side",
    ingredients = {
        medkit = 1,
        electronics = 5
    },
    result = "medkit",
    resultQuantity = 3,
    craftTime = 12,
    requiredFaction = "Sith",
    category = "medical"
})

-- Check if player can craft recipe
function GM:CanCraft(ply, recipeID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local recipe = self:GetRecipe(recipeID)
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Check faction requirement
    if recipe.requiredFaction then
        local playerFaction = self:GetPlayerFaction(ply)
        if playerFaction ~= recipe.requiredFaction then
            return false, string.format("Requires %s faction", recipe.requiredFaction)
        end
    end
    
    -- Check rank requirement
    if recipe.requiredRank then
        local playerRank = self:GetPlayerRank(ply)
        -- This would need a rank comparison system
        -- For now, just check if player has a rank
        if not playerRank then
            return false, string.format("Requires rank: %s", recipe.requiredRank)
        end
    end
    
    -- Check ingredients
    for itemID, quantity in pairs(recipe.ingredients) do
        if not self:HasInventoryItem(ply, itemID, quantity) then
            local item = self:GetItem(itemID)
            local itemName = item and item.name or itemID
            return false, string.format("Missing: %dx %s", quantity, itemName)
        end
    end
    
    return true
end

-- Craft an item
function GM:CraftItem(ply, recipeID)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local recipe = self:GetRecipe(recipeID)
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Check if can craft
    local canCraft, reason = self:CanCraft(ply, recipeID)
    if not canCraft then
        return false, reason
    end
    
    -- Check if result can fit in inventory
    if not self:HasInventorySpace(ply, recipe.result, recipe.resultQuantity) then
        return false, "Not enough inventory space for crafted item"
    end
    
    -- Remove ingredients
    for itemID, quantity in pairs(recipe.ingredients) do
        local success = self:RemoveInventoryItem(ply, itemID, quantity)
        if not success then
            -- This shouldn't happen if CanCraft passed
            return false, "Failed to remove ingredients"
        end
    end
    
    -- Add result
    local success, msg = self:AddInventoryItem(ply, recipe.result, recipe.resultQuantity)
    if not success then
        -- Try to refund ingredients
        for itemID, quantity in pairs(recipe.ingredients) do
            self:AddInventoryItem(ply, itemID, quantity)
        end
        return false, "Failed to add crafted item: " .. msg
    end
    
    local resultItem = self:GetItem(recipe.result)
    local resultName = resultItem and resultItem.name or recipe.result
    
    self:Log(string.format("%s crafted %dx %s using recipe: %s",
        ply:Nick(), recipe.resultQuantity, resultName, recipe.name))
    
    return true, recipe.resultQuantity, resultName
end

-- Commands

-- List recipes command
GM:RegisterCommand("recipes", function(ply, args)
    local faction = GAMEMODE:GetPlayerFaction(ply)
    local recipes = GAMEMODE:GetFactionRecipes(faction)
    
    if table.Count(recipes) == 0 then
        GAMEMODE:Notify(ply, "No recipes available", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== CRAFTING RECIPES ===")
    
    for recipeID, recipe in pairs(recipes) do
        ply:ChatPrint(string.format("[%s] %s", recipeID, recipe.name))
        ply:ChatPrint("  " .. recipe.description)
        
        -- Show ingredients
        local ingredientsList = {}
        for itemID, quantity in pairs(recipe.ingredients) do
            local item = GAMEMODE:GetItem(itemID)
            local itemName = item and item.name or itemID
            table.insert(ingredientsList, string.format("%dx %s", quantity, itemName))
        end
        
        ply:ChatPrint("  Ingredients: " .. table.concat(ingredientsList, ", "))
        
        -- Show result
        local resultItem = GAMEMODE:GetItem(recipe.result)
        local resultName = resultItem and resultItem.name or recipe.result
        ply:ChatPrint(string.format("  Result: %dx %s", recipe.resultQuantity, resultName))
        
        -- Show if can craft
        local canCraft, reason = GAMEMODE:CanCraft(ply, recipeID)
        if canCraft then
            ply:ChatPrint("  Status: ✓ Can craft")
        else
            ply:ChatPrint("  Status: ✗ " .. reason)
        end
        
        ply:ChatPrint("")
    end
    
    ply:ChatPrint("Use /craft <recipeID> to craft an item")
    ply:ChatPrint("=======================")
end, false, "View available crafting recipes")

-- Craft command
GM:RegisterCommand("craft", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /craft <recipeID>", NOTIFY_ERROR)
        GAMEMODE:Notify(ply, "Use /recipes to see available recipes", NOTIFY_HINT)
        return
    end
    
    local recipeID = args[1]
    
    -- Check if player is already crafting
    if ply.IsCrafting then
        GAMEMODE:Notify(ply, "You are already crafting something", NOTIFY_ERROR)
        return
    end
    
    local recipe = GAMEMODE:GetRecipe(recipeID)
    if not recipe then
        GAMEMODE:Notify(ply, "Invalid recipe: " .. recipeID, NOTIFY_ERROR)
        return
    end
    
    -- Check if can craft
    local canCraft, reason = GAMEMODE:CanCraft(ply, recipeID)
    if not canCraft then
        GAMEMODE:Notify(ply, "Cannot craft: " .. reason, NOTIFY_ERROR)
        return
    end
    
    -- Mark as crafting
    ply.IsCrafting = true
    
    GAMEMODE:Notify(ply, string.format("Crafting %s... (%d seconds)", recipe.name, recipe.craftTime), NOTIFY_GENERIC)
    
    -- Craft after delay
    timer.Simple(recipe.craftTime, function()
        if not IsValid(ply) then return end
        
        ply.IsCrafting = false
        
        local success, quantity, itemName = GAMEMODE:CraftItem(ply, recipeID)
        
        if success then
            GAMEMODE:Notify(ply, string.format("Successfully crafted %dx %s!", quantity, itemName), NOTIFY_GENERIC)
        else
            GAMEMODE:Notify(ply, "Crafting failed: " .. quantity, NOTIFY_ERROR)
        end
    end)
end, false, "Craft an item using a recipe")

-- Check recipe command
GM:RegisterCommand("recipeinfo", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /recipeinfo <recipeID>", NOTIFY_ERROR)
        return
    end
    
    local recipeID = args[1]
    local recipe = GAMEMODE:GetRecipe(recipeID)
    
    if not recipe then
        GAMEMODE:Notify(ply, "Invalid recipe: " .. recipeID, NOTIFY_ERROR)
        return
    end
    
    ply:ChatPrint("=== RECIPE INFO ===")
    ply:ChatPrint("Name: " .. recipe.name)
    ply:ChatPrint("Description: " .. recipe.description)
    ply:ChatPrint("Category: " .. recipe.category)
    
    if recipe.requiredFaction then
        ply:ChatPrint("Required Faction: " .. recipe.requiredFaction)
    end
    
    if recipe.requiredRank then
        ply:ChatPrint("Required Rank: " .. recipe.requiredRank)
    end
    
    ply:ChatPrint("Craft Time: " .. recipe.craftTime .. " seconds")
    
    ply:ChatPrint("Ingredients:")
    for itemID, quantity in pairs(recipe.ingredients) do
        local item = GAMEMODE:GetItem(itemID)
        local itemName = item and item.name or itemID
        local hasAmount = GAMEMODE:GetInventoryItemCount(ply, itemID)
        ply:ChatPrint(string.format("  %dx %s (You have: %d)", quantity, itemName, hasAmount))
    end
    
    local resultItem = GAMEMODE:GetItem(recipe.result)
    local resultName = resultItem and resultItem.name or recipe.result
    ply:ChatPrint(string.format("Result: %dx %s", recipe.resultQuantity, resultName))
    
    local canCraft, reason = GAMEMODE:CanCraft(ply, recipeID)
    if canCraft then
        ply:ChatPrint("Status: ✓ You can craft this")
    else
        ply:ChatPrint("Status: ✗ " .. reason)
    end
    
    ply:ChatPrint("==================")
end, false, "View detailed information about a recipe")

-- Print loaded recipes
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_CraftingInit", function()
        GAMEMODE:Log(string.format("Loaded %d crafting recipes", table.Count(GAMEMODE.CraftingRecipes)))
    end)
end
