--[[
    Project Sovereign - Phase 7
    Advanced AI and NPC Systems
    
    Implements intelligent NPC factions with dynamic behavior.
]]--

if SERVER then
    GAMEMODE.NPCSystems = GAMEMODE.NPCSystems or {}
    GAMEMODE.NPCData = GAMEMODE.NPCData or {
        npcFactions = {},
        npcBehaviors = {},
        activeConflicts = {}
    }
    
    -- NPC Faction behaviors
    local NPC_BEHAVIORS = {
        AGGRESSIVE = "aggressive",
        DEFENSIVE = "defensive",
        EXPANSIONIST = "expansionist",
        TRADER = "trader",
        NEUTRAL = "neutral"
    }
    
    -- Configuration
    local CONFIG = {
        UpdateInterval = 30, -- Update AI every 30 seconds
        ConflictCheckInterval = 300, -- Check for conflicts every 5 minutes
        ResourceGatherRate = 100,
        ExpansionCost = 5000,
        ConflictResolutionTime = 1800 -- 30 minutes
    }
    
    -- Initialize NPC systems
    function GAMEMODE:InitializeNPCSystems()
        self:LoadNPCData()
        
        -- Initialize default NPC factions if empty
        if table.IsEmpty(self.NPCData.npcFactions) then
            self:InitializeDefaultNPCFactions()
        end
        
        -- Start AI update timer
        timer.Create("NPCUpdate", CONFIG.UpdateInterval, 0, function()
            self:UpdateNPCBehaviors()
        end)
        
        -- Start conflict checker
        timer.Create("NPCConflictCheck", CONFIG.ConflictCheckInterval, 0, function()
            self:CheckNPCConflicts()
        end)
        
        print("[NPC Systems] Advanced AI system initialized with " .. table.Count(self.NPCData.npcFactions) .. " NPC factions")
    end
    
    -- Initialize default NPC factions
    function GAMEMODE:InitializeDefaultNPCFactions()
        local defaultFactions = {
            {
                id = "trade_consortium",
                name = "Galactic Trade Consortium",
                behavior = NPC_BEHAVIORS.TRADER,
                strength = 100,
                resources = 50000,
                territories = {},
                hostileTowards = {},
                alliedWith = {}
            },
            {
                id = "pirate_clans",
                name = "Outer Rim Pirates",
                behavior = NPC_BEHAVIORS.AGGRESSIVE,
                strength = 150,
                resources = 25000,
                territories = {},
                hostileTowards = {"trade_consortium"},
                alliedWith = {}
            },
            {
                id = "mercenary_guild",
                name = "Mercenary Guild",
                behavior = NPC_BEHAVIORS.NEUTRAL,
                strength = 120,
                resources = 30000,
                territories = {},
                hostileTowards = {},
                alliedWith = {}
            },
            {
                id = "tech_collective",
                name = "Technology Collective",
                behavior = NPC_BEHAVIORS.DEFENSIVE,
                strength = 80,
                resources = 60000,
                territories = {},
                hostileTowards = {},
                alliedWith = {}
            },
            {
                id = "expansion_front",
                name = "Expansion Front",
                behavior = NPC_BEHAVIORS.EXPANSIONIST,
                strength = 180,
                resources = 40000,
                territories = {},
                hostileTowards = {},
                alliedWith = {}
            }
        }
        
        for _, faction in ipairs(defaultFactions) do
            self.NPCData.npcFactions[faction.id] = faction
        end
        
        self:SaveNPCData()
    end
    
    -- Update NPC behaviors
    function GAMEMODE:UpdateNPCBehaviors()
        for factionId, faction in pairs(self.NPCData.npcFactions) do
            -- Gather resources
            faction.resources = faction.resources + CONFIG.ResourceGatherRate
            
            -- Execute behavior based on type
            if faction.behavior == NPC_BEHAVIORS.AGGRESSIVE then
                self:ExecuteAggressiveBehavior(faction)
            elseif faction.behavior == NPC_BEHAVIORS.DEFENSIVE then
                self:ExecuteDefensiveBehavior(faction)
            elseif faction.behavior == NPC_BEHAVIORS.EXPANSIONIST then
                self:ExecuteExpansionistBehavior(faction)
            elseif faction.behavior == NPC_BEHAVIORS.TRADER then
                self:ExecuteTraderBehavior(faction)
            elseif faction.behavior == NPC_BEHAVIORS.NEUTRAL then
                self:ExecuteNeutralBehavior(faction)
            end
        end
        
        self:SaveNPCData()
    end
    
    -- Aggressive behavior
    function GAMEMODE:ExecuteAggressiveBehavior(faction)
        -- Look for targets to attack
        if faction.resources > 10000 and math.random() > 0.7 then
            -- Find weakest neighboring faction
            local target = self:FindWeakestNPCFaction(faction.id)
            if target then
                self:InitiateNPCConflict(faction.id, target.id, "raid")
            end
        end
    end
    
    -- Defensive behavior
    function GAMEMODE:ExecuteDefensiveBehavior(faction)
        -- Build up defenses
        if faction.resources > 5000 and math.random() > 0.5 then
            faction.strength = faction.strength + math.random(5, 15)
            faction.resources = faction.resources - 5000
        end
    end
    
    -- Expansionist behavior
    function GAMEMODE:ExecuteExpansionistBehavior(faction)
        -- Try to claim new territories
        if faction.resources > CONFIG.ExpansionCost and math.random() > 0.6 then
            -- Get unclaimed sectors
            local sectors = self:GetAllSectors()
            if sectors then
                for sectorId, sector in pairs(sectors) do
                    -- Check if sector is unclaimed
                    local claimed = false
                    for _, npcFaction in pairs(self.NPCData.npcFactions) do
                        if table.HasValue(npcFaction.territories or {}, sectorId) then
                            claimed = true
                            break
                        end
                    end
                    
                    if not claimed then
                        table.insert(faction.territories, sectorId)
                        faction.resources = faction.resources - CONFIG.ExpansionCost
                        
                        self:NotifyAll(string.format("[NPC] %s has expanded into %s", 
                            faction.name, sector.name or sectorId), NOTIFY_GENERIC)
                        break
                    end
                end
            end
        end
    end
    
    -- Trader behavior
    function GAMEMODE:ExecuteTraderBehavior(faction)
        -- Generate income from trade
        if math.random() > 0.5 then
            faction.resources = faction.resources + math.random(500, 1500)
        end
    end
    
    -- Neutral behavior
    function GAMEMODE:ExecuteNeutralBehavior(faction)
        -- Slow resource accumulation
        faction.resources = faction.resources + math.random(50, 200)
    end
    
    -- Find weakest NPC faction
    function GAMEMODE:FindWeakestNPCFaction(excludeId)
        local weakest = nil
        local lowestStrength = math.huge
        
        for factionId, faction in pairs(self.NPCData.npcFactions) do
            if factionId ~= excludeId and faction.strength < lowestStrength then
                weakest = faction
                lowestStrength = faction.strength
            end
        end
        
        return weakest
    end
    
    -- Check for NPC conflicts
    function GAMEMODE:CheckNPCConflicts()
        -- Check for territory disputes
        for factionId1, faction1 in pairs(self.NPCData.npcFactions) do
            for factionId2, faction2 in pairs(self.NPCData.npcFactions) do
                if factionId1 ~= factionId2 then
                    -- Check if they share borders or have hostile relations
                    if table.HasValue(faction1.hostileTowards or {}, factionId2) then
                        if math.random() > 0.8 then -- 20% chance
                            self:InitiateNPCConflict(factionId1, factionId2, "territory_dispute")
                        end
                    end
                end
            end
        end
    end
    
    -- Initiate NPC conflict
    function GAMEMODE:InitiateNPCConflict(attackerId, defenderId, conflictType)
        local attacker = self.NPCData.npcFactions[attackerId]
        local defender = self.NPCData.npcFactions[defenderId]
        
        if not attacker or not defender then return end
        
        -- Check if conflict already exists
        for _, conflict in pairs(self.NPCData.activeConflicts) do
            if (conflict.attacker == attackerId and conflict.defender == defenderId) or
               (conflict.attacker == defenderId and conflict.defender == attackerId) then
                return -- Conflict already active
            end
        end
        
        local conflictId = "npc_conflict_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        self.NPCData.activeConflicts[conflictId] = {
            id = conflictId,
            attacker = attackerId,
            defender = defenderId,
            type = conflictType,
            startTime = CurTime(),
            endTime = CurTime() + CONFIG.ConflictResolutionTime,
            attackerLosses = 0,
            defenderLosses = 0
        }
        
        self:NotifyAll(string.format("[NPC CONFLICT] %s is attacking %s!", 
            attacker.name, defender.name), NOTIFY_GENERIC)
        
        -- Schedule resolution
        timer.Simple(CONFIG.ConflictResolutionTime, function()
            self:ResolveNPCConflict(conflictId)
        end)
        
        self:SaveNPCData()
    end
    
    -- Resolve NPC conflict
    function GAMEMODE:ResolveNPCConflict(conflictId)
        local conflict = self.NPCData.activeConflicts[conflictId]
        if not conflict then return end
        
        local attacker = self.NPCData.npcFactions[conflict.attacker]
        local defender = self.NPCData.npcFactions[conflict.defender]
        
        if not attacker or not defender then return end
        
        -- Calculate outcome based on strength
        local attackerPower = attacker.strength + math.random(-20, 20)
        local defenderPower = defender.strength + math.random(-20, 20)
        
        local winner, loser
        if attackerPower > defenderPower then
            winner = attacker
            loser = defender
            
            -- Attacker takes territory
            if #loser.territories > 0 then
                local takenTerritory = table.remove(loser.territories, 1)
                table.insert(winner.territories, takenTerritory)
            end
        else
            winner = defender
            loser = attacker
        end
        
        -- Apply losses
        loser.strength = math.max(50, loser.strength - math.random(10, 30))
        loser.resources = math.max(0, loser.resources - math.random(5000, 15000))
        
        winner.strength = winner.strength + math.random(5, 15)
        
        self:NotifyAll(string.format("[NPC CONFLICT] %s defeated %s in combat!", 
            winner.name, loser.name), NOTIFY_GENERIC)
        
        -- Remove conflict
        self.NPCData.activeConflicts[conflictId] = nil
        
        self:SaveNPCData()
    end
    
    -- Get NPC faction by ID
    function GAMEMODE:GetNPCFaction(factionId)
        return self.NPCData.npcFactions[factionId]
    end
    
    -- Get all NPC factions
    function GAMEMODE:GetAllNPCFactions()
        return self.NPCData.npcFactions
    end
    
    -- Save NPC data
    function GAMEMODE:SaveNPCData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.NPCData, true)
        file.Write("project_sovereign/npc_systems.txt", data)
    end
    
    -- Load NPC data
    function GAMEMODE:LoadNPCData()
        if file.Exists("project_sovereign/npc_systems.txt", "DATA") then
            local data = file.Read("project_sovereign/npc_systems.txt", "DATA")
            if data then
                self.NPCData = util.JSONToTable(data) or self.NPCData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_npcfactions", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== NPC Factions ===")
        
        for factionId, faction in pairs(GAMEMODE.NPCData.npcFactions) do
            ply:ChatPrint(string.format("%s (%s)", faction.name, faction.behavior))
            ply:ChatPrint(string.format("  Strength: %d | Resources: %s | Territories: %d",
                faction.strength, GAMEMODE:FormatCredits(faction.resources), #faction.territories))
        end
    end)
    
    concommand.Add("ps_npcconflicts", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Active NPC Conflicts ===")
        
        if table.IsEmpty(GAMEMODE.NPCData.activeConflicts) then
            ply:ChatPrint("No active conflicts")
            return
        end
        
        for conflictId, conflict in pairs(GAMEMODE.NPCData.activeConflicts) do
            local attacker = GAMEMODE.NPCData.npcFactions[conflict.attacker]
            local defender = GAMEMODE.NPCData.npcFactions[conflict.defender]
            
            if attacker and defender then
                local timeLeft = math.max(0, conflict.endTime - CurTime())
                ply:ChatPrint(string.format("%s vs %s (%s)", 
                    attacker.name, defender.name, conflict.type))
                ply:ChatPrint(string.format("  Time remaining: %d seconds", timeLeft))
            end
        end
    end)
    
    concommand.Add("ps_npcinfo", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_npcinfo <factionId>")
            return
        end
        
        local faction = GAMEMODE:GetNPCFaction(args[1])
        if not faction then
            ply:ChatPrint("NPC faction not found")
            return
        end
        
        ply:ChatPrint("=== " .. faction.name .. " ===")
        ply:ChatPrint("Behavior: " .. faction.behavior)
        ply:ChatPrint("Strength: " .. faction.strength)
        ply:ChatPrint("Resources: " .. GAMEMODE:FormatCredits(faction.resources))
        ply:ChatPrint("Territories: " .. #faction.territories)
        
        if #faction.hostileTowards > 0 then
            ply:ChatPrint("\nHostile towards:")
            for _, enemyId in ipairs(faction.hostileTowards) do
                ply:ChatPrint("  - " .. enemyId)
            end
        end
        
        if #faction.alliedWith > 0 then
            ply:ChatPrint("\nAllied with:")
            for _, allyId in ipairs(faction.alliedWith) do
                ply:ChatPrint("  - " .. allyId)
            end
        end
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "NPCSystems_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeNPCSystems()
        end)
    end)
end

print("[Phase 7] Advanced AI and NPC Systems loaded")
