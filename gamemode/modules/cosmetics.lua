--[[
    Project Sovereign - Phase 9
    Customization and Monetization System
    
    Cosmetic systems for characters, gear, and bases (non-pay-to-win).
]]--

if SERVER then
    GAMEMODE.Cosmetics = GAMEMODE.Cosmetics or {}
    GAMEMODE.CosmeticData = GAMEMODE.CosmeticData or {
        playerCosmetics = {},
        factionCustomizations = {},
        shop = {}
    }
    
    -- Cosmetic types
    local COSMETIC_CATEGORIES = {
        CHARACTER = "character",
        WEAPON = "weapon",
        ARMOR = "armor",
        BASE = "base",
        FACTION = "faction",
        EMOTE = "emote",
        EFFECT = "effect"
    }
    
    -- Cosmetic shop items
    local SHOP_ITEMS = {
        -- Character cosmetics
        {
            id = "skin_elite",
            name = "Elite Armor Skin",
            description = "Prestigious armor appearance",
            category = COSMETIC_CATEGORIES.CHARACTER,
            rarity = "rare",
            price = 15000,
            premiumOnly = false
        },
        {
            id = "skin_gold",
            name = "Golden Armor",
            description = "Luxurious golden finish",
            category = COSMETIC_CATEGORIES.CHARACTER,
            rarity = "legendary",
            price = 50000,
            premiumOnly = false
        },
        {
            id = "helmet_custom",
            name = "Custom Helmet Design",
            description = "Unique helmet appearance",
            category = COSMETIC_CATEGORIES.ARMOR,
            rarity = "uncommon",
            price = 8000,
            premiumOnly = false
        },
        -- Weapon cosmetics
        {
            id = "weapon_chrome",
            name = "Chrome Weapon Skin",
            description = "Shiny chrome finish",
            category = COSMETIC_CATEGORIES.WEAPON,
            rarity = "rare",
            price = 12000,
            premiumOnly = false
        },
        {
            id = "weapon_plasma",
            name = "Plasma Effect",
            description = "Glowing plasma effect",
            category = COSMETIC_CATEGORIES.WEAPON,
            rarity = "legendary",
            price = 40000,
            premiumOnly = false
        },
        -- Base cosmetics
        {
            id = "banner_custom",
            name = "Custom Banner",
            description = "Personalized faction banner",
            category = COSMETIC_CATEGORIES.BASE,
            rarity = "uncommon",
            price = 10000,
            premiumOnly = false
        },
        {
            id = "base_lights",
            name = "Base Lighting Effects",
            description = "Colorful lighting for your base",
            category = COSMETIC_CATEGORIES.BASE,
            rarity = "rare",
            price = 20000,
            premiumOnly = false
        },
        {
            id = "hologram_display",
            name = "Holographic Display",
            description = "Advanced hologram projectors",
            category = COSMETIC_CATEGORIES.BASE,
            rarity = "legendary",
            price = 45000,
            premiumOnly = false
        },
        -- Emotes and effects
        {
            id = "emote_salute",
            name = "Military Salute",
            description = "Show respect to your commanders",
            category = COSMETIC_CATEGORIES.EMOTE,
            rarity = "common",
            price = 5000,
            premiumOnly = false
        },
        {
            id = "trail_energy",
            name = "Energy Trail",
            description = "Leave an energy trail behind you",
            category = COSMETIC_CATEGORIES.EFFECT,
            rarity = "rare",
            price = 18000,
            premiumOnly = false
        },
        {
            id = "aura_power",
            name = "Power Aura",
            description = "Emanate an aura of power",
            category = COSMETIC_CATEGORIES.EFFECT,
            rarity = "legendary",
            price = 35000,
            premiumOnly = false
        },
        -- Faction customizations
        {
            id = "faction_emblem",
            name = "Custom Faction Emblem",
            description = "Design your faction's emblem",
            category = COSMETIC_CATEGORIES.FACTION,
            rarity = "rare",
            price = 25000,
            premiumOnly = false
        },
        {
            id = "faction_colors",
            name = "Custom Faction Colors",
            description = "Choose your faction's colors",
            category = COSMETIC_CATEGORIES.FACTION,
            rarity = "uncommon",
            price = 15000,
            premiumOnly = false
        }
    }
    
    -- Initialize cosmetic system
    function GAMEMODE:InitializeCosmetics()
        self:LoadCosmeticData()
        
        -- Initialize shop
        for _, item in ipairs(SHOP_ITEMS) do
            self.CosmeticData.shop[item.id] = item
        end
        
        print("[Cosmetics] Customization system initialized with " .. #SHOP_ITEMS .. " items")
    end
    
    -- Purchase cosmetic
    function GAMEMODE:PurchaseCosmetic(ply, itemId)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        local item = self.CosmeticData.shop[itemId]
        if not item then return false, "Item not found" end
        
        -- Check if already owned
        local steamId = ply:SteamID()
        if not self.CosmeticData.playerCosmetics[steamId] then
            self.CosmeticData.playerCosmetics[steamId] = {
                steamId = steamId,
                playerName = ply:Nick(),
                owned = {},
                equipped = {}
            }
        end
        
        local playerData = self.CosmeticData.playerCosmetics[steamId]
        
        if playerData.owned[itemId] then
            return false, "Already owned"
        end
        
        -- Check if player can afford
        if not self:CanAfford(ply, item.price) then
            return false, "Insufficient credits"
        end
        
        -- Purchase item
        self:RemovePlayerCredits(ply, item.price)
        
        playerData.owned[itemId] = {
            purchasedAt = os.time(),
            itemData = item
        }
        
        self:SaveCosmeticData()
        
        ply:ChatPrint(string.format("Purchased: %s", item.name))
        
        return true, "Purchase successful"
    end
    
    -- Equip cosmetic
    function GAMEMODE:EquipCosmetic(ply, itemId, slot)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        local steamId = ply:SteamID()
        local playerData = self.CosmeticData.playerCosmetics[steamId]
        
        if not playerData or not playerData.owned[itemId] then
            return false, "Item not owned"
        end
        
        local item = self.CosmeticData.shop[itemId]
        slot = slot or item.category
        
        -- Equip item
        playerData.equipped[slot] = itemId
        
        self:SaveCosmeticData()
        
        -- Apply cosmetic effect
        self:ApplyCosmetic(ply, itemId)
        
        return true, string.format("Equipped: %s", item.name)
    end
    
    -- Unequip cosmetic
    function GAMEMODE:UnequipCosmetic(ply, slot)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        local steamId = ply:SteamID()
        local playerData = self.CosmeticData.playerCosmetics[steamId]
        
        if not playerData then return false, "No cosmetics data" end
        
        playerData.equipped[slot] = nil
        
        self:SaveCosmeticData()
        
        return true, "Cosmetic unequipped"
    end
    
    -- Apply cosmetic effect
    function GAMEMODE:ApplyCosmetic(ply, itemId)
        local item = self.CosmeticData.shop[itemId]
        if not item then return end
        
        -- Apply visual effects based on category
        if item.category == COSMETIC_CATEGORIES.CHARACTER then
            -- Apply character skin/model
            -- This would integrate with player model system
        elseif item.category == COSMETIC_CATEGORIES.WEAPON then
            -- Apply weapon skin
            -- This would modify weapon appearance
        elseif item.category == COSMETIC_CATEGORIES.EFFECT then
            -- Apply particle effects
            -- This would create visual effects around player
        end
    end
    
    -- Customize faction appearance
    function GAMEMODE:CustomizeFaction(faction, customizationType, data)
        if not self.CosmeticData.factionCustomizations[faction] then
            self.CosmeticData.factionCustomizations[faction] = {
                faction = faction,
                emblem = nil,
                colors = {primary = Color(255, 255, 255), secondary = Color(200, 200, 200)},
                banner = nil,
                motto = ""
            }
        end
        
        local customization = self.CosmeticData.factionCustomizations[faction]
        
        if customizationType == "emblem" then
            customization.emblem = data
        elseif customizationType == "colors" then
            customization.colors = data
        elseif customizationType == "banner" then
            customization.banner = data
        elseif customizationType == "motto" then
            customization.motto = data
        end
        
        self:SaveCosmeticData()
        
        return true
    end
    
    -- Get player cosmetics
    function GAMEMODE:GetPlayerCosmetics(ply)
        return self.CosmeticData.playerCosmetics[ply:SteamID()]
    end
    
    -- Get faction customization
    function GAMEMODE:GetFactionCustomization(faction)
        return self.CosmeticData.factionCustomizations[faction]
    end
    
    -- Get shop items by category
    function GAMEMODE:GetShopItemsByCategory(category)
        local items = {}
        
        for _, item in pairs(self.CosmeticData.shop) do
            if not category or item.category == category then
                table.insert(items, item)
            end
        end
        
        return items
    end
    
    -- Save cosmetic data
    function GAMEMODE:SaveCosmeticData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.CosmeticData, true)
        file.Write("project_sovereign/cosmetics.txt", data)
    end
    
    -- Load cosmetic data
    function GAMEMODE:LoadCosmeticData()
        if file.Exists("project_sovereign/cosmetics.txt", "DATA") then
            local data = file.Read("project_sovereign/cosmetics.txt", "DATA")
            if data then
                self.CosmeticData = util.JSONToTable(data) or self.CosmeticData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_shop", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local category = args[1]
        
        ply:ChatPrint("=== Cosmetic Shop ===")
        
        local items = GAMEMODE:GetShopItemsByCategory(category)
        
        for _, item in ipairs(items) do
            ply:ChatPrint(string.format("[%s] %s - %s", 
                item.rarity:upper(), item.name, GAMEMODE:FormatCredits(item.price)))
            ply:ChatPrint("  " .. item.description)
        end
        
        ply:ChatPrint("\nCategories: character, weapon, armor, base, faction, emote, effect")
    end)
    
    concommand.Add("ps_buycosmetic", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_buycosmetic <itemId>")
            return
        end
        
        local success, message = GAMEMODE:PurchaseCosmetic(ply, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_equipcosmetic", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_equipcosmetic <itemId> [slot]")
            return
        end
        
        local success, message = GAMEMODE:EquipCosmetic(ply, args[1], args[2])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_unequipcosmetic", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_unequipcosmetic <slot>")
            return
        end
        
        local success, message = GAMEMODE:UnequipCosmetic(ply, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_mycosmetics", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local playerData = GAMEMODE:GetPlayerCosmetics(ply)
        
        if not playerData then
            ply:ChatPrint("You don't own any cosmetics")
            return
        end
        
        ply:ChatPrint("=== Your Cosmetics ===")
        
        ply:ChatPrint("\nOwned:")
        for itemId, _ in pairs(playerData.owned) do
            local item = GAMEMODE.CosmeticData.shop[itemId]
            if item then
                ply:ChatPrint(string.format("- %s (%s)", item.name, item.category))
            end
        end
        
        ply:ChatPrint("\nEquipped:")
        for slot, itemId in pairs(playerData.equipped) do
            local item = GAMEMODE.CosmeticData.shop[itemId]
            if item then
                ply:ChatPrint(string.format("- %s: %s", slot, item.name))
            end
        end
    end)
    
    concommand.Add("ps_customizefaction", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: ps_customizefaction <type> <data>")
            ply:ChatPrint("Types: emblem, colors, banner, motto")
            return
        end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        local data = table.concat(args, " ", 2)
        GAMEMODE:CustomizeFaction(faction, args[1], data)
        
        ply:ChatPrint("Faction customization updated")
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Cosmetics_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeCosmetics()
        end)
    end)
end

print("[Phase 9] Customization and Monetization System loaded")
