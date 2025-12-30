--[[
    Project Sovereign - Phase 3
    Base Upgrades System
    
    Handles faction base upgrades and improvements.
]]--

if SERVER then
    GAMEMODE.BaseUpgrades = GAMEMODE.BaseUpgrades or {}
    GAMEMODE.BaseUpgradeData = GAMEMODE.BaseUpgradeData or {
        factionBases = {},
        upgrades = {}
    }
    
    -- Upgrade definitions
    local UPGRADE_TYPES = {
        {
            id = "defenses_1",
            name = "Basic Defenses",
            description = "Improves base defensive capabilities",
            cost = 5000,
            prerequisites = {},
            effects = {defenseBonus = 10}
        },
        {
            id = "defenses_2",
            name = "Advanced Defenses",
            description = "Advanced defensive systems",
            cost = 15000,
            prerequisites = {"defenses_1"},
            effects = {defenseBonus = 25}
        },
        {
            id = "defenses_3",
            name = "Elite Defenses",
            description = "Elite defensive installations",
            cost = 30000,
            prerequisites = {"defenses_2"},
            effects = {defenseBonus = 50}
        },
        {
            id = "income_1",
            name = "Resource Harvester",
            description = "Increases passive income",
            cost = 7500,
            prerequisites = {},
            effects = {incomeBonus = 100}
        },
        {
            id = "income_2",
            name = "Advanced Harvester",
            description = "Advanced resource collection",
            cost = 20000,
            prerequisites = {"income_1"},
            effects = {incomeBonus = 300}
        },
        {
            id = "income_3",
            name = "Industrial Complex",
            description = "Massive income generation",
            cost = 50000,
            prerequisites = {"income_2"},
            effects = {incomeBonus = 750}
        },
        {
            id = "storage_1",
            name = "Expanded Storage",
            description = "Increases faction budget cap",
            cost = 10000,
            prerequisites = {},
            effects = {storageBonus = 50000}
        },
        {
            id = "storage_2",
            name = "Massive Vault",
            description = "Huge storage capacity",
            cost = 25000,
            prerequisites = {"storage_1"},
            effects = {storageBonus = 150000}
        },
        {
            id = "medical_1",
            name = "Medical Bay",
            description = "Faster health regeneration in base",
            cost = 8000,
            prerequisites = {},
            effects = {healthRegen = 5}
        },
        {
            id = "medical_2",
            name = "Advanced Medical",
            description = "Enhanced healing capabilities",
            cost = 18000,
            prerequisites = {"medical_1"},
            effects = {healthRegen = 15}
        },
        {
            id = "armory_1",
            name = "Armory",
            description = "Better loadouts for faction members",
            cost = 12000,
            prerequisites = {},
            effects = {loadoutBonus = 1}
        },
        {
            id = "armory_2",
            name = "Advanced Armory",
            description = "Elite equipment access",
            cost = 30000,
            prerequisites = {"armory_1"},
            effects = {loadoutBonus = 2}
        },
        {
            id = "tech_1",
            name = "Research Lab",
            description = "Unlock advanced technologies",
            cost = 15000,
            prerequisites = {},
            effects = {techLevel = 1}
        },
        {
            id = "tech_2",
            name = "Advanced Research",
            description = "Cutting-edge research",
            cost = 35000,
            prerequisites = {"tech_1"},
            effects = {techLevel = 2}
        }
    }
    
    -- Initialize base upgrades
    function GAMEMODE:InitializeBaseUpgrades()
        self:LoadBaseUpgradeData()
        
        -- Create faction bases if they don't exist
        for factionId, factionData in pairs(self.Factions or {}) do
            if not self.BaseUpgradeData.factionBases[factionId] then
                self.BaseUpgradeData.factionBases[factionId] = {
                    faction = factionId,
                    upgrades = {},
                    level = 1
                }
            end
        end
        
        self:SaveBaseUpgradeData()
        print("[Base Upgrades] Base upgrade system initialized")
    end
    
    -- Get upgrade by ID
    function GAMEMODE:GetUpgrade(upgradeId)
        for _, upgrade in ipairs(UPGRADE_TYPES) do
            if upgrade.id == upgradeId then
                return upgrade
            end
        end
        return nil
    end
    
    -- Check if faction can purchase upgrade
    function GAMEMODE:CanPurchaseUpgrade(faction, upgradeId)
        local upgrade = self:GetUpgrade(upgradeId)
        if not upgrade then return false, "Invalid upgrade" end
        
        local base = self.BaseUpgradeData.factionBases[faction]
        if not base then return false, "No base found" end
        
        -- Check if already purchased
        if base.upgrades[upgradeId] then
            return false, "Already purchased"
        end
        
        -- Check prerequisites
        for _, prereq in ipairs(upgrade.prerequisites) do
            if not base.upgrades[prereq] then
                return false, "Missing prerequisite: " .. prereq
            end
        end
        
        -- Check faction budget
        if self.GetFactionBudget then
            local budget = self:GetFactionBudget(faction)
            if budget < upgrade.cost then
                return false, "Insufficient faction budget"
            end
        end
        
        return true
    end
    
    -- Purchase upgrade
    function GAMEMODE:PurchaseUpgrade(faction, upgradeId)
        local canPurchase, reason = self:CanPurchaseUpgrade(faction, upgradeId)
        if not canPurchase then
            return false, reason
        end
        
        local upgrade = self:GetUpgrade(upgradeId)
        local base = self.BaseUpgradeData.factionBases[faction]
        
        -- Deduct cost from faction budget
        if self.RemoveFactionBudget then
            self:RemoveFactionBudget(faction, upgrade.cost)
        end
        
        -- Add upgrade
        base.upgrades[upgradeId] = {
            purchasedAt = os.time(),
            effects = upgrade.effects
        }
        
        -- Update base level
        base.level = table.Count(base.upgrades)
        
        self:SaveBaseUpgradeData()
        
        -- Notify faction
        self:NotifyAll(string.format("%s purchased upgrade: %s", faction, upgrade.name), NOTIFY_GENERIC)
        self:LogEvent("BASE", string.format("%s purchased %s for %d credits", 
            faction, upgrade.name, upgrade.cost))
        
        return true, "Upgrade purchased successfully"
    end
    
    -- Get faction base info
    function GAMEMODE:GetFactionBase(faction)
        return self.BaseUpgradeData.factionBases[faction]
    end
    
    -- Get total effects for faction base
    function GAMEMODE:GetBaseEffects(faction)
        local base = self:GetFactionBase(faction)
        if not base then return {} end
        
        local totalEffects = {
            defenseBonus = 0,
            incomeBonus = 0,
            storageBonus = 0,
            healthRegen = 0,
            loadoutBonus = 0,
            techLevel = 0
        }
        
        for upgradeId, upgradeData in pairs(base.upgrades) do
            for effect, value in pairs(upgradeData.effects) do
                totalEffects[effect] = (totalEffects[effect] or 0) + value
            end
        end
        
        return totalEffects
    end
    
    -- Apply base effects to player
    function GAMEMODE:ApplyBaseEffects(ply, baseFaction)
        if not self:IsValidPlayer(ply) then return end
        
        local effects = self:GetBaseEffects(baseFaction)
        
        -- Apply health regeneration if in base radius
        if effects.healthRegen > 0 then
            -- This would be applied via a timer when player is in base
            ply.baseHealthRegen = effects.healthRegen
        end
    end
    
    -- Save base upgrade data
    function GAMEMODE:SaveBaseUpgradeData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.BaseUpgradeData, true)
        file.Write("project_sovereign/base_upgrades.txt", data)
    end
    
    -- Load base upgrade data
    function GAMEMODE:LoadBaseUpgradeData()
        if file.Exists("project_sovereign/base_upgrades.txt", "DATA") then
            local data = file.Read("project_sovereign/base_upgrades.txt", "DATA")
            if data then
                self.BaseUpgradeData = util.JSONToTable(data) or self.BaseUpgradeData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_baseinfo", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        local base = GAMEMODE:GetFactionBase(faction)
        if not base then
            ply:ChatPrint("No base found for your faction")
            return
        end
        
        ply:ChatPrint("=== " .. faction .. " Base Info ===")
        ply:ChatPrint("Base Level: " .. base.level)
        ply:ChatPrint("\nActive Upgrades:")
        
        for upgradeId, _ in pairs(base.upgrades) do
            local upgrade = GAMEMODE:GetUpgrade(upgradeId)
            if upgrade then
                ply:ChatPrint("- " .. upgrade.name)
            end
        end
        
        ply:ChatPrint("\nTotal Effects:")
        local effects = GAMEMODE:GetBaseEffects(faction)
        for effect, value in pairs(effects) do
            if value > 0 then
                ply:ChatPrint(string.format("  %s: +%s", effect, value))
            end
        end
    end)
    
    concommand.Add("ps_upgrades", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        ply:ChatPrint("=== Available Upgrades ===")
        
        for _, upgrade in ipairs(UPGRADE_TYPES) do
            local canPurchase, reason = GAMEMODE:CanPurchaseUpgrade(faction, upgrade.id)
            local status = canPurchase and "[AVAILABLE]" or "[LOCKED]"
            
            ply:ChatPrint(string.format("%s %s - %s credits", 
                status, upgrade.name, GAMEMODE:FormatCredits(upgrade.cost)))
            ply:ChatPrint("  " .. upgrade.description)
            
            if not canPurchase then
                ply:ChatPrint("  Reason: " .. reason)
            end
        end
    end)
    
    concommand.Add("ps_purchaseupgrade", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Only faction leaders/admins can purchase upgrades")
            return
        end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_purchaseupgrade <upgradeId>")
            return
        end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        local success, message = GAMEMODE:PurchaseUpgrade(faction, args[1])
        ply:ChatPrint(message)
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "BaseUpgrades_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeBaseUpgrades()
        end)
    end)
end

print("[Phase 3] Base Upgrades System loaded")
