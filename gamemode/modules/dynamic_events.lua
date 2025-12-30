--[[
    Project Sovereign - Phase 4
    Dynamic Events System
    
    Handles dynamic galaxy events like invasions, anomalies, and disasters.
]]--

if SERVER then
    GAMEMODE.DynamicEvents = GAMEMODE.DynamicEvents or {}
    GAMEMODE.DynamicEventData = GAMEMODE.DynamicEventData or {
        activeEvents = {},
        eventHistory = {}
    }
    
    -- Event types
    local EVENT_TYPES = {
        {
            id = "npc_invasion",
            name = "NPC Invasion",
            description = "An NPC faction is invading a sector",
            frequency = 3600, -- Every hour
            duration = 1800, -- 30 minutes
            severity = "high",
            rewards = {credits = 5000, reputation = 100}
        },
        {
            id = "pirate_raid",
            name = "Pirate Raid",
            description = "Pirates are attacking trade routes",
            frequency = 2400,
            duration = 900,
            severity = "medium",
            rewards = {credits = 2000, reputation = 50}
        },
        {
            id = "anomaly",
            name = "Galactic Anomaly",
            description = "Strange phenomenon detected",
            frequency = 7200,
            duration = 3600,
            severity = "low",
            rewards = {credits = 3000, reputation = 75, items = {"artifacts"}}
        },
        {
            id = "resource_boom",
            name = "Resource Boom",
            description = "Increased resource spawn in sector",
            frequency = 1800,
            duration = 1200,
            severity = "low",
            rewards = {resourceBonus = 2.0}
        },
        {
            id = "faction_war",
            name = "NPC Faction War",
            description = "Two NPC factions fighting over territory",
            frequency = 5400,
            duration = 2400,
            severity = "high",
            rewards = {credits = 7500, reputation = 150}
        },
        {
            id = "supply_crisis",
            name = "Supply Crisis",
            description = "Trade disruption in sector",
            frequency = 4800,
            duration = 1800,
            severity = "medium",
            rewards = {credits = 3500, reputation = 60}
        },
        {
            id = "research_opportunity",
            name = "Research Opportunity",
            description = "Rare technology discovered",
            frequency = 9600,
            duration = 2400,
            severity = "rare",
            rewards = {credits = 10000, reputation = 200, items = {"technology"}}
        }
    }
    
    -- Initialize dynamic events
    function GAMEMODE:InitializeDynamicEvents()
        self:LoadDynamicEventData()
        
        -- Start event spawner
        timer.Create("DynamicEventSpawner", 60, 0, function()
            self:CheckSpawnDynamicEvent()
        end)
        
        -- Update active events
        timer.Create("DynamicEventUpdater", 30, 0, function()
            self:UpdateDynamicEvents()
        end)
        
        print("[Dynamic Events] Dynamic event system initialized")
    end
    
    -- Check if we should spawn a new event
    function GAMEMODE:CheckSpawnDynamicEvent()
        -- Random chance to spawn event
        if math.random() > 0.3 then return end -- 30% chance per check
        
        -- Don't spawn too many events at once
        if table.Count(self.DynamicEventData.activeEvents) >= 3 then return end
        
        -- Select random event type
        local eventType = EVENT_TYPES[math.random(1, #EVENT_TYPES)]
        
        -- Get random sector
        local sectors = self:GetAllSectors()
        if not sectors or table.IsEmpty(sectors) then return end
        
        local sectorId = table.GetKeys(sectors)[math.random(1, table.Count(sectors))]
        
        self:SpawnDynamicEvent(eventType.id, sectorId)
    end
    
    -- Spawn dynamic event
    function GAMEMODE:SpawnDynamicEvent(eventTypeId, sectorId)
        local eventType = nil
        for _, et in ipairs(EVENT_TYPES) do
            if et.id == eventTypeId then
                eventType = et
                break
            end
        end
        
        if not eventType then return false end
        
        local eventId = "event_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        local event = {
            id = eventId,
            type = eventTypeId,
            name = eventType.name,
            description = eventType.description,
            sector = sectorId,
            startTime = CurTime(),
            endTime = CurTime() + eventType.duration,
            severity = eventType.severity,
            rewards = eventType.rewards,
            participants = {},
            completed = false
        }
        
        self.DynamicEventData.activeEvents[eventId] = event
        
        -- Notify all players
        local sector = self:GetSector(sectorId)
        local sectorName = sector and sector.name or "Unknown"
        
        self:NotifyAll(string.format("[EVENT] %s in %s!", eventType.name, sectorName), NOTIFY_GENERIC)
        self:LogEvent("DYNAMIC_EVENT", string.format("Event spawned: %s in %s", eventType.name, sectorName))
        
        self:SaveDynamicEventData()
        return true
    end
    
    -- Update active events
    function GAMEMODE:UpdateDynamicEvents()
        local toRemove = {}
        
        for eventId, event in pairs(self.DynamicEventData.activeEvents) do
            -- Check if event expired
            if CurTime() >= event.endTime then
                table.insert(toRemove, eventId)
                
                -- Move to history
                table.insert(self.DynamicEventData.eventHistory, {
                    type = event.type,
                    sector = event.sector,
                    completedAt = os.time(),
                    participants = table.Count(event.participants)
                })
                
                -- Keep history limited
                if #self.DynamicEventData.eventHistory > 50 then
                    table.remove(self.DynamicEventData.eventHistory, 1)
                end
                
                -- Notify about event end
                local sector = self:GetSector(event.sector)
                local sectorName = sector and sector.name or "Unknown"
                self:NotifyAll(string.format("[EVENT] %s in %s has ended!", event.name, sectorName), NOTIFY_GENERIC)
            end
        end
        
        -- Remove expired events
        for _, eventId in ipairs(toRemove) do
            self.DynamicEventData.activeEvents[eventId] = nil
        end
        
        if #toRemove > 0 then
            self:SaveDynamicEventData()
        end
    end
    
    -- Participate in event
    function GAMEMODE:ParticipateInEvent(ply, eventId)
        local event = self.DynamicEventData.activeEvents[eventId]
        if not event then return false, "Event not found" end
        
        if event.participants[ply:SteamID()] then
            return false, "Already participating"
        end
        
        event.participants[ply:SteamID()] = {
            joinedAt = CurTime(),
            contribution = 0
        }
        
        ply:ChatPrint(string.format("You are now participating in: %s", event.name))
        self:SaveDynamicEventData()
        
        return true
    end
    
    -- Complete event for player
    function GAMEMODE:CompleteEventForPlayer(ply, eventId)
        local event = self.DynamicEventData.activeEvents[eventId]
        if not event then return false, "Event not found" end
        
        if not event.participants[ply:SteamID()] then
            return false, "Not participating in event"
        end
        
        -- Award rewards
        if event.rewards.credits and self.AddPlayerCredits then
            self:AddPlayerCredits(ply, event.rewards.credits)
            ply:ChatPrint("Earned " .. self:FormatCredits(event.rewards.credits))
        end
        
        if event.rewards.reputation and self.AddReputation then
            local faction = self:GetPlayerFaction(ply)
            if faction then
                self:AddReputation(ply, faction, event.rewards.reputation)
                ply:ChatPrint("Earned " .. event.rewards.reputation .. " reputation")
            end
        end
        
        if event.rewards.items and self.AddItemToInventory then
            for _, itemId in ipairs(event.rewards.items) do
                self:AddItemToInventory(ply, itemId, 1)
                ply:ChatPrint("Received: " .. itemId)
            end
        end
        
        event.participants[ply:SteamID()].completed = true
        self:SaveDynamicEventData()
        
        return true, "Event completed!"
    end
    
    -- Get active events
    function GAMEMODE:GetActiveEvents()
        return self.DynamicEventData.activeEvents
    end
    
    -- Get event by ID
    function GAMEMODE:GetEvent(eventId)
        return self.DynamicEventData.activeEvents[eventId]
    end
    
    -- Save dynamic event data
    function GAMEMODE:SaveDynamicEventData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.DynamicEventData, true)
        file.Write("project_sovereign/dynamic_events.txt", data)
    end
    
    -- Load dynamic event data
    function GAMEMODE:LoadDynamicEventData()
        if file.Exists("project_sovereign/dynamic_events.txt", "DATA") then
            local data = file.Read("project_sovereign/dynamic_events.txt", "DATA")
            if data then
                self.DynamicEventData = util.JSONToTable(data) or self.DynamicEventData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_activeevents", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Active Dynamic Events ===")
        
        if table.IsEmpty(GAMEMODE.DynamicEventData.activeEvents) then
            ply:ChatPrint("No active events")
            return
        end
        
        for eventId, event in pairs(GAMEMODE.DynamicEventData.activeEvents) do
            local sector = GAMEMODE:GetSector(event.sector)
            local sectorName = sector and sector.name or "Unknown"
            local timeLeft = math.floor(event.endTime - CurTime())
            
            ply:ChatPrint(string.format("[%s] %s in %s", event.severity:upper(), event.name, sectorName))
            ply:ChatPrint(string.format("  Time Left: %d seconds", timeLeft))
            ply:ChatPrint(string.format("  Participants: %d", table.Count(event.participants)))
        end
    end)
    
    concommand.Add("ps_joinevent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_joinevent <eventId>")
            return
        end
        
        local success, message = GAMEMODE:ParticipateInEvent(ply, args[1])
        if not success then
            ply:ChatPrint(message)
        end
    end)
    
    concommand.Add("ps_completeevent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_completeevent <eventId>")
            return
        end
        
        local success, message = GAMEMODE:CompleteEventForPlayer(ply, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_spawnevent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: ps_spawnevent <eventType> <sectorId>")
            return
        end
        
        local success = GAMEMODE:SpawnDynamicEvent(args[1], args[2])
        ply:ChatPrint(success and "Event spawned" or "Failed to spawn event")
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "DynamicEvents_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeDynamicEvents()
        end)
    end)
end

print("[Phase 4] Dynamic Events System loaded")
