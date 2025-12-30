--[[
    Project Sovereign - Phase 5
    Faction Diplomacy System
    
    Handles faction alliances, wars, and diplomatic relations.
]]--

if SERVER then
    GAMEMODE.Diplomacy = GAMEMODE.Diplomacy or {}
    GAMEMODE.DiplomacyData = GAMEMODE.DiplomacyData or {
        relations = {},
        alliances = {},
        wars = {},
        treaties = {}
    }
    
    -- Relation types
    local RELATION_TYPES = {
        ALLIED = "allied",
        FRIENDLY = "friendly",
        NEUTRAL = "neutral",
        UNFRIENDLY = "unfriendly",
        HOSTILE = "hostile",
        WAR = "war"
    }
    
    -- Configuration
    local CONFIG = {
        AllianceCost = 10000, -- Faction budget cost
        WarDeclarationCost = 5000,
        TreatyCost = 15000,
        MinAllianceTime = 3600, -- 1 hour minimum
        WarExhaustionRate = 100 -- Per death
    }
    
    -- Initialize diplomacy system
    function GAMEMODE:InitializeDiplomacy()
        self:LoadDiplomacyData()
        
        -- Set default relations if empty
        if table.IsEmpty(self.DiplomacyData.relations) then
            self:InitializeDefaultRelations()
        end
        
        print("[Diplomacy] Diplomacy system initialized")
    end
    
    -- Initialize default faction relations
    function GAMEMODE:InitializeDefaultRelations()
        local factions = self.Factions or {}
        
        for faction1, _ in pairs(factions) do
            self.DiplomacyData.relations[faction1] = self.DiplomacyData.relations[faction1] or {}
            
            for faction2, _ in pairs(factions) do
                if faction1 ~= faction2 then
                    -- Set default relations based on lore
                    if (faction1 == "Republic" and faction2 == "CIS") or 
                       (faction1 == "CIS" and faction2 == "Republic") or
                       (faction1 == "Jedi" and faction2 == "Sith") or
                       (faction1 == "Sith" and faction2 == "Jedi") then
                        self.DiplomacyData.relations[faction1][faction2] = RELATION_TYPES.HOSTILE
                    else
                        self.DiplomacyData.relations[faction1][faction2] = RELATION_TYPES.NEUTRAL
                    end
                end
            end
        end
        
        self:SaveDiplomacyData()
    end
    
    -- Get relation between factions
    function GAMEMODE:GetFactionRelation(faction1, faction2)
        if faction1 == faction2 then return RELATION_TYPES.ALLIED end
        
        if self.DiplomacyData.relations[faction1] and 
           self.DiplomacyData.relations[faction1][faction2] then
            return self.DiplomacyData.relations[faction1][faction2]
        end
        
        return RELATION_TYPES.NEUTRAL
    end
    
    -- Set faction relation
    function GAMEMODE:SetFactionRelation(faction1, faction2, relationType)
        if faction1 == faction2 then return false, "Cannot set relation with same faction" end
        
        if not RELATION_TYPES[relationType:upper()] then
            return false, "Invalid relation type"
        end
        
        self.DiplomacyData.relations[faction1] = self.DiplomacyData.relations[faction1] or {}
        self.DiplomacyData.relations[faction1][faction2] = relationType
        
        -- Mirror relation
        self.DiplomacyData.relations[faction2] = self.DiplomacyData.relations[faction2] or {}
        self.DiplomacyData.relations[faction2][faction1] = relationType
        
        self:SaveDiplomacyData()
        
        return true, "Relation updated"
    end
    
    -- Propose alliance
    function GAMEMODE:ProposeAlliance(faction1, faction2)
        if faction1 == faction2 then return false, "Cannot ally with same faction" end
        
        -- Check if already allied
        if self:GetFactionRelation(faction1, faction2) == RELATION_TYPES.ALLIED then
            return false, "Already allied"
        end
        
        -- Check if at war
        if self:IsAtWar(faction1, faction2) then
            return false, "Cannot ally while at war"
        end
        
        -- Check faction budget
        if self.GetFactionBudget then
            local budget = self:GetFactionBudget(faction1)
            if budget < CONFIG.AllianceCost then
                return false, "Insufficient faction budget"
            end
        end
        
        -- Create alliance
        local allianceId = "alliance_" .. os.time()
        
        self.DiplomacyData.alliances[allianceId] = {
            id = allianceId,
            factions = {faction1, faction2},
            createdAt = os.time(),
            status = "active"
        }
        
        -- Update relations
        self:SetFactionRelation(faction1, faction2, RELATION_TYPES.ALLIED)
        
        -- Deduct cost
        if self.RemoveFactionBudget then
            self:RemoveFactionBudget(faction1, CONFIG.AllianceCost)
        end
        
        self:SaveDiplomacyData()
        
        self:NotifyAll(string.format("%s and %s have formed an alliance!", faction1, faction2), NOTIFY_GENERIC)
        
        return true, "Alliance formed"
    end
    
    -- Declare war
    function GAMEMODE:DeclareWar(faction1, faction2, reason)
        if faction1 == faction2 then return false, "Cannot declare war on same faction" end
        
        -- Check if already at war
        if self:IsAtWar(faction1, faction2) then
            return false, "Already at war"
        end
        
        -- Check faction budget
        if self.GetFactionBudget then
            local budget = self:GetFactionBudget(faction1)
            if budget < CONFIG.WarDeclarationCost then
                return false, "Insufficient faction budget"
            end
        end
        
        -- Break any alliance
        self:BreakAlliance(faction1, faction2)
        
        -- Create war
        local warId = "war_" .. os.time()
        
        self.DiplomacyData.wars[warId] = {
            id = warId,
            attacker = faction1,
            defender = faction2,
            reason = reason or "Undeclared",
            startedAt = os.time(),
            status = "active",
            casualties = {[faction1] = 0, [faction2] = 0},
            warExhaustion = {[faction1] = 0, [faction2] = 0}
        }
        
        -- Update relations
        self:SetFactionRelation(faction1, faction2, RELATION_TYPES.WAR)
        
        -- Deduct cost
        if self.RemoveFactionBudget then
            self:RemoveFactionBudget(faction1, CONFIG.WarDeclarationCost)
        end
        
        self:SaveDiplomacyData()
        
        self:NotifyAll(string.format("%s has declared war on %s! Reason: %s", 
            faction1, faction2, reason or "Undeclared"), NOTIFY_GENERIC)
        
        return true, "War declared"
    end
    
    -- Check if factions are at war
    function GAMEMODE:IsAtWar(faction1, faction2)
        for _, war in pairs(self.DiplomacyData.wars) do
            if war.status == "active" then
                if (war.attacker == faction1 and war.defender == faction2) or
                   (war.attacker == faction2 and war.defender == faction1) then
                    return true, war
                end
            end
        end
        return false
    end
    
    -- Break alliance
    function GAMEMODE:BreakAlliance(faction1, faction2)
        for allianceId, alliance in pairs(self.DiplomacyData.alliances) do
            if alliance.status == "active" then
                if table.HasValue(alliance.factions, faction1) and 
                   table.HasValue(alliance.factions, faction2) then
                    alliance.status = "broken"
                    alliance.brokenAt = os.time()
                    
                    -- Reset to neutral
                    self:SetFactionRelation(faction1, faction2, RELATION_TYPES.NEUTRAL)
                    
                    self:SaveDiplomacyData()
                    return true
                end
            end
        end
        return false
    end
    
    -- End war
    function GAMEMODE:EndWar(faction1, faction2, winner)
        local isAtWar, war = self:IsAtWar(faction1, faction2)
        if not isAtWar then return false, "Not at war" end
        
        war.status = "ended"
        war.endedAt = os.time()
        war.winner = winner
        
        -- Reset relations to hostile
        self:SetFactionRelation(faction1, faction2, RELATION_TYPES.HOSTILE)
        
        self:SaveDiplomacyData()
        
        if winner then
            self:NotifyAll(string.format("War between %s and %s has ended! %s is victorious!", 
                faction1, faction2, winner), NOTIFY_GENERIC)
        else
            self:NotifyAll(string.format("War between %s and %s has ended in a stalemate!", 
                faction1, faction2), NOTIFY_GENERIC)
        end
        
        return true, "War ended"
    end
    
    -- Add war casualties
    function GAMEMODE:AddWarCasualty(faction)
        for _, war in pairs(self.DiplomacyData.wars) do
            if war.status == "active" then
                if war.attacker == faction or war.defender == faction then
                    war.casualties[faction] = (war.casualties[faction] or 0) + 1
                    war.warExhaustion[faction] = (war.warExhaustion[faction] or 0) + CONFIG.WarExhaustionRate
                    
                    self:SaveDiplomacyData()
                    return
                end
            end
        end
    end
    
    -- Save diplomacy data
    function GAMEMODE:SaveDiplomacyData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.DiplomacyData, true)
        file.Write("project_sovereign/diplomacy.txt", data)
    end
    
    -- Load diplomacy data
    function GAMEMODE:LoadDiplomacyData()
        if file.Exists("project_sovereign/diplomacy.txt", "DATA") then
            local data = file.Read("project_sovereign/diplomacy.txt", "DATA")
            if data then
                self.DiplomacyData = util.JSONToTable(data) or self.DiplomacyData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_relations", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        ply:ChatPrint("=== " .. faction .. " Diplomatic Relations ===")
        
        for otherFaction, relation in pairs(GAMEMODE.DiplomacyData.relations[faction] or {}) do
            ply:ChatPrint(string.format("%s: %s", otherFaction, relation:upper()))
        end
    end)
    
    concommand.Add("ps_proposealliance", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_proposealliance <faction>")
            return
        end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        local success, message = GAMEMODE:ProposeAlliance(faction, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_declarewar", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_declarewar <faction> [reason]")
            return
        end
        
        local faction = GAMEMODE:GetPlayerFaction(ply)
        if not faction then
            ply:ChatPrint("You are not in a faction")
            return
        end
        
        local reason = table.concat(args, " ", 2)
        local success, message = GAMEMODE:DeclareWar(faction, args[1], reason)
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_wars", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Active Wars ===")
        
        local hasWars = false
        for _, war in pairs(GAMEMODE.DiplomacyData.wars) do
            if war.status == "active" then
                hasWars = true
                ply:ChatPrint(string.format("%s vs %s", war.attacker, war.defender))
                ply:ChatPrint(string.format("  Casualties: %s: %d | %s: %d",
                    war.attacker, war.casualties[war.attacker] or 0,
                    war.defender, war.casualties[war.defender] or 0))
            end
        end
        
        if not hasWars then
            ply:ChatPrint("No active wars")
        end
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Diplomacy_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeDiplomacy()
        end)
    end)
    
    -- Track casualties in wars
    hook.Add("PlayerDeath", "Diplomacy_TrackCasualties", function(victim, inflictor, attacker)
        if not IsValid(victim) then return end
        
        local victimFaction = GAMEMODE:GetPlayerFaction(victim)
        if victimFaction then
            GAMEMODE:AddWarCasualty(victimFaction)
        end
    end)
end

print("[Phase 5] Faction Diplomacy System loaded")
