--[[
    Project Sovereign - Phase 6
    Player-Created Content System
    
    Allows players to create custom factions, missions, and events.
]]--

if SERVER then
    GAMEMODE.PlayerContent = GAMEMODE.PlayerContent or {}
    GAMEMODE.PlayerContentData = GAMEMODE.PlayerContentData or {
        customFactions = {},
        customMissions = {},
        customEvents = {},
        customBases = {}
    }
    
    -- Configuration
    local CONFIG = {
        CreateFactionCost = 50000,
        CreateMissionCost = 5000,
        CreateEventCost = 10000,
        CreateBaseCost = 25000,
        MaxCustomFactionsPerPlayer = 1,
        MaxCustomMissionsPerPlayer = 5,
        MaxCustomEventsPerPlayer = 3,
        MaxCustomBasesPerPlayer = 2
    }
    
    -- Initialize player content system
    function GAMEMODE:InitializePlayerContent()
        self:LoadPlayerContentData()
        
        print("[Player Content] Player-created content system initialized")
    end
    
    -- Create custom faction
    function GAMEMODE:CreateCustomFaction(ply, factionName, description, color)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        -- Check player limit
        local playerFactions = 0
        for _, faction in pairs(self.PlayerContentData.customFactions) do
            if faction.creator == ply:SteamID() then
                playerFactions = playerFactions + 1
            end
        end
        
        if playerFactions >= CONFIG.MaxCustomFactionsPerPlayer then
            return false, "Maximum custom factions reached"
        end
        
        -- Check cost
        if not self:CanAfford(ply, CONFIG.CreateFactionCost) then
            return false, "Insufficient credits"
        end
        
        -- Validate name
        if not factionName or factionName == "" then
            return false, "Invalid faction name"
        end
        
        -- Check if name exists
        local factionId = string.lower(string.gsub(factionName, " ", "_"))
        if self.PlayerContentData.customFactions[factionId] then
            return false, "Faction name already exists"
        end
        
        -- Create faction
        self:RemovePlayerCredits(ply, CONFIG.CreateFactionCost)
        
        self.PlayerContentData.customFactions[factionId] = {
            id = factionId,
            name = factionName,
            description = description or "A custom player faction",
            creator = ply:SteamID(),
            creatorName = ply:Nick(),
            createdAt = os.time(),
            color = color or Color(100, 100, 255),
            members = {},
            ranks = {"Recruit", "Member", "Officer", "Leader"},
            budget = 10000,
            approved = false
        }
        
        self:SavePlayerContentData()
        
        self:NotifyAll(string.format("%s created a new faction: %s", ply:Nick(), factionName), NOTIFY_GENERIC)
        
        return true, "Custom faction created! Waiting for admin approval."
    end
    
    -- Create custom mission
    function GAMEMODE:CreateCustomMission(ply, missionData)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        -- Check player limit
        local playerMissions = 0
        for _, mission in pairs(self.PlayerContentData.customMissions) do
            if mission.creator == ply:SteamID() and mission.status == "active" then
                playerMissions = playerMissions + 1
            end
        end
        
        if playerMissions >= CONFIG.MaxCustomMissionsPerPlayer then
            return false, "Maximum custom missions reached"
        end
        
        -- Check cost
        if not self:CanAfford(ply, CONFIG.CreateMissionCost) then
            return false, "Insufficient credits"
        end
        
        -- Validate mission data
        if not missionData.name or not missionData.description then
            return false, "Invalid mission data"
        end
        
        -- Create mission
        self:RemovePlayerCredits(ply, CONFIG.CreateMissionCost)
        
        local missionId = "custom_mission_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        self.PlayerContentData.customMissions[missionId] = {
            id = missionId,
            name = missionData.name,
            description = missionData.description,
            type = missionData.type or "custom",
            creator = ply:SteamID(),
            creatorName = ply:Nick(),
            createdAt = os.time(),
            objectives = missionData.objectives or {},
            rewards = missionData.rewards or {credits = 1000},
            difficulty = missionData.difficulty or 1,
            status = "pending",
            completions = 0
        }
        
        self:SavePlayerContentData()
        
        return true, "Custom mission created! Waiting for admin approval."
    end
    
    -- Create custom event
    function GAMEMODE:CreateCustomEvent(ply, eventData)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        -- Check player limit
        local playerEvents = 0
        for _, event in pairs(self.PlayerContentData.customEvents) do
            if event.creator == ply:SteamID() and event.status == "active" then
                playerEvents = playerEvents + 1
            end
        end
        
        if playerEvents >= CONFIG.MaxCustomEventsPerPlayer then
            return false, "Maximum custom events reached"
        end
        
        -- Check cost
        if not self:CanAfford(ply, CONFIG.CreateEventCost) then
            return false, "Insufficient credits"
        end
        
        -- Validate event data
        if not eventData.name or not eventData.description then
            return false, "Invalid event data"
        end
        
        -- Create event
        self:RemovePlayerCredits(ply, CONFIG.CreateEventCost)
        
        local eventId = "custom_event_" .. os.time() .. "_" .. math.random(1000, 9999)
        
        self.PlayerContentData.customEvents[eventId] = {
            id = eventId,
            name = eventData.name,
            description = eventData.description,
            type = eventData.type or "custom",
            creator = ply:SteamID(),
            creatorName = ply:Nick(),
            createdAt = os.time(),
            duration = eventData.duration or 1800,
            rewards = eventData.rewards or {credits = 2000},
            status = "pending",
            participants = 0
        }
        
        self:SavePlayerContentData()
        
        return true, "Custom event created! Waiting for admin approval."
    end
    
    -- Create custom base
    function GAMEMODE:CreateCustomBase(ply, baseName, location)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        -- Check player limit
        local playerBases = 0
        for _, base in pairs(self.PlayerContentData.customBases) do
            if base.creator == ply:SteamID() then
                playerBases = playerBases + 1
            end
        end
        
        if playerBases >= CONFIG.MaxCustomBasesPerPlayer then
            return false, "Maximum custom bases reached"
        end
        
        -- Check cost
        if not self:CanAfford(ply, CONFIG.CreateBaseCost) then
            return false, "Insufficient credits"
        end
        
        -- Create base
        self:RemovePlayerCredits(ply, CONFIG.CreateBaseCost)
        
        local baseId = "custom_base_" .. ply:SteamID() .. "_" .. os.time()
        
        self.PlayerContentData.customBases[baseId] = {
            id = baseId,
            name = baseName or (ply:Nick() .. "'s Base"),
            creator = ply:SteamID(),
            creatorName = ply:Nick(),
            createdAt = os.time(),
            location = location or ply:GetPos(),
            structures = {},
            permissions = {
                [ply:SteamID()] = "owner"
            },
            budget = 5000
        }
        
        self:SavePlayerContentData()
        
        return true, "Custom base created!"
    end
    
    -- Approve custom content (admin only)
    function GAMEMODE:ApproveCustomContent(contentType, contentId)
        local content = nil
        
        if contentType == "faction" then
            content = self.PlayerContentData.customFactions[contentId]
            if content then content.approved = true end
        elseif contentType == "mission" then
            content = self.PlayerContentData.customMissions[contentId]
            if content then content.status = "active" end
        elseif contentType == "event" then
            content = self.PlayerContentData.customEvents[contentId]
            if content then content.status = "active" end
        end
        
        if not content then
            return false, "Content not found"
        end
        
        self:SavePlayerContentData()
        
        return true, "Content approved"
    end
    
    -- Get player's custom content
    function GAMEMODE:GetPlayerCustomContent(ply)
        local content = {
            factions = {},
            missions = {},
            events = {},
            bases = {}
        }
        
        for _, faction in pairs(self.PlayerContentData.customFactions) do
            if faction.creator == ply:SteamID() then
                table.insert(content.factions, faction)
            end
        end
        
        for _, mission in pairs(self.PlayerContentData.customMissions) do
            if mission.creator == ply:SteamID() then
                table.insert(content.missions, mission)
            end
        end
        
        for _, event in pairs(self.PlayerContentData.customEvents) do
            if event.creator == ply:SteamID() then
                table.insert(content.events, event)
            end
        end
        
        for _, base in pairs(self.PlayerContentData.customBases) do
            if base.creator == ply:SteamID() then
                table.insert(content.bases, base)
            end
        end
        
        return content
    end
    
    -- Save player content data
    function GAMEMODE:SavePlayerContentData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.PlayerContentData, true)
        file.Write("project_sovereign/player_content.txt", data)
    end
    
    -- Load player content data
    function GAMEMODE:LoadPlayerContentData()
        if file.Exists("project_sovereign/player_content.txt", "DATA") then
            local data = file.Read("project_sovereign/player_content.txt", "DATA")
            if data then
                self.PlayerContentData = util.JSONToTable(data) or self.PlayerContentData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_createfaction", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_createfaction <name> [description]")
            return
        end
        
        local name = args[1]
        local description = table.concat(args, " ", 2)
        
        local success, message = GAMEMODE:CreateCustomFaction(ply, name, description)
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_createmission", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: ps_createmission <name> <description>")
            return
        end
        
        local missionData = {
            name = args[1],
            description = table.concat(args, " ", 2)
        }
        
        local success, message = GAMEMODE:CreateCustomMission(ply, missionData)
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_createevent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: ps_createevent <name> <description>")
            return
        end
        
        local eventData = {
            name = args[1],
            description = table.concat(args, " ", 2)
        }
        
        local success, message = GAMEMODE:CreateCustomEvent(ply, eventData)
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_createbase", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local baseName = args[1] or (ply:Nick() .. "'s Base")
        local success, message = GAMEMODE:CreateCustomBase(ply, baseName, ply:GetPos())
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_mycontent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local content = GAMEMODE:GetPlayerCustomContent(ply)
        
        ply:ChatPrint("=== Your Custom Content ===")
        
        ply:ChatPrint("\nCustom Factions: " .. #content.factions)
        for _, faction in ipairs(content.factions) do
            local status = faction.approved and "[APPROVED]" or "[PENDING]"
            ply:ChatPrint(string.format("  %s %s", status, faction.name))
        end
        
        ply:ChatPrint("\nCustom Missions: " .. #content.missions)
        for _, mission in ipairs(content.missions) do
            ply:ChatPrint(string.format("  [%s] %s", mission.status:upper(), mission.name))
        end
        
        ply:ChatPrint("\nCustom Events: " .. #content.events)
        for _, event in ipairs(content.events) do
            ply:ChatPrint(string.format("  [%s] %s", event.status:upper(), event.name))
        end
        
        ply:ChatPrint("\nCustom Bases: " .. #content.bases)
        for _, base in ipairs(content.bases) do
            ply:ChatPrint(string.format("  %s", base.name))
        end
    end)
    
    concommand.Add("ps_approvecontent", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] or not args[2] then
            ply:ChatPrint("Usage: ps_approvecontent <type> <id>")
            ply:ChatPrint("Types: faction, mission, event")
            return
        end
        
        local success, message = GAMEMODE:ApproveCustomContent(args[1], args[2])
        ply:ChatPrint(message)
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "PlayerContent_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializePlayerContent()
        end)
    end)
end

print("[Phase 6] Player-Created Content System loaded")
