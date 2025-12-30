--[[
    Mission System Module - Phase 2
    Dynamic missions with combat, economy, and exploration types
]]--

-- Initialize mission data
GM.Missions = GM.Missions or {
    available = {},
    active = {},
    completed = {},
    nextMissionID = 1
}

-- Mission types
GM.MissionTypes = {
    COMBAT = {
        name = "Combat",
        rewards = {credits = 1000, reputation = 50}
    },
    ECONOMY = {
        name = "Economy",
        rewards = {credits = 1500, reputation = 30}
    },
    EXPLORATION = {
        name = "Exploration",
        rewards = {credits = 800, reputation = 40}
    }
}

-- Initialize missions
local function InitMissions()
    GAMEMODE:Log("Mission system initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitMissions", InitMissions)
end

-- Get mission data path
local function GetMissionDataPath()
    return "project_sovereign/missions.txt"
end

-- Save mission data
function GM:SaveMissions()
    if not SERVER then return false end
    
    local data = {
        available = self.Missions.available,
        active = self.Missions.active,
        completed = self.Missions.completed,
        nextMissionID = self.Missions.nextMissionID
    }
    
    local json = util.TableToJSON(data, true)
    if not json then
        self:ErrorLog("Failed to serialize mission data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write(GetMissionDataPath(), json)
    
    self:DebugLog("Saved mission data")
    return true
end

-- Load mission data
function GM:LoadMissions()
    if not SERVER then return false end
    
    local filePath = GetMissionDataPath()
    
    if not file.Exists(filePath, "DATA") then
        self:Log("No mission data found, generating initial missions")
        self:GenerateRandomMissions(5)
        return true
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read mission data")
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse mission data")
        return false
    end
    
    self.Missions.available = data.available or {}
    self.Missions.active = data.active or {}
    self.Missions.completed = data.completed or {}
    self.Missions.nextMissionID = data.nextMissionID or 1
    
    self:Log("Loaded mission data successfully")
    return true
end

-- Generate a random mission
function GM:GenerateRandomMission(missionType, faction)
    local missionID = self.Missions.nextMissionID
    self.Missions.nextMissionID = self.Missions.nextMissionID + 1
    
    local typeData = self.MissionTypes[missionType]
    if not typeData then
        missionType = "COMBAT"
        typeData = self.MissionTypes.COMBAT
    end
    
    local mission = {
        id = missionID,
        type = missionType,
        typeName = typeData.name,
        faction = faction or "Any",
        title = self:GenerateMissionTitle(missionType),
        description = self:GenerateMissionDescription(missionType),
        objectives = self:GenerateMissionObjectives(missionType),
        rewards = {
            credits = typeData.rewards.credits + math.random(-200, 200),
            reputation = typeData.rewards.reputation + math.random(-10, 10)
        },
        difficulty = math.random(1, 5),
        timeLimit = 1800, -- 30 minutes in seconds
        created = os.time()
    }
    
    return mission
end

-- Generate mission title
function GM:GenerateMissionTitle(missionType)
    local titles = {
        COMBAT = {
            "Defend the Outpost",
            "Raid Enemy Territory",
            "Eliminate High-Value Target",
            "Secure the Perimeter",
            "Assault Enemy Base"
        },
        ECONOMY = {
            "Supply Run",
            "Resource Collection",
            "Trade Negotiation",
            "Salvage Operation",
            "Delivery Mission"
        },
        EXPLORATION = {
            "Scout Neutral Zone",
            "Map Unknown Territory",
            "Locate Strategic Position",
            "Reconnaissance Mission",
            "Survey the Area"
        }
    }
    
    local typeTitle = titles[missionType]
    if typeTitle then
        return typeTitle[math.random(1, #typeTitle)]
    end
    
    return "Unknown Mission"
end

-- Generate mission description
function GM:GenerateMissionDescription(missionType)
    local descriptions = {
        COMBAT = "Engage hostile forces and complete combat objectives.",
        ECONOMY = "Complete economic tasks to support your faction.",
        EXPLORATION = "Explore and report on strategic locations."
    }
    
    return descriptions[missionType] or "Complete the mission objectives."
end

-- Generate mission objectives
function GM:GenerateMissionObjectives(missionType)
    local objectives = {}
    
    if missionType == "COMBAT" then
        table.insert(objectives, {
            description = "Eliminate " .. math.random(5, 15) .. " hostile targets",
            progress = 0,
            target = math.random(5, 15),
            completed = false
        })
    elseif missionType == "ECONOMY" then
        table.insert(objectives, {
            description = "Deliver " .. math.random(3, 10) .. " supply crates",
            progress = 0,
            target = math.random(3, 10),
            completed = false
        })
    elseif missionType == "EXPLORATION" then
        table.insert(objectives, {
            description = "Visit " .. math.random(3, 7) .. " checkpoints",
            progress = 0,
            target = math.random(3, 7),
            completed = false
        })
    end
    
    return objectives
end

-- Generate random missions
function GM:GenerateRandomMissions(count)
    count = count or 3
    
    local types = {"COMBAT", "ECONOMY", "EXPLORATION"}
    
    for i = 1, count do
        local missionType = types[math.random(1, #types)]
        local mission = self:GenerateRandomMission(missionType)
        self.Missions.available[mission.id] = mission
    end
    
    self:SaveMissions()
    return true
end

-- Accept a mission
function GM:AcceptMission(ply, missionID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local mission = self.Missions.available[missionID]
    if not mission then
        return false, "Mission not found"
    end
    
    -- Check if player already has an active mission
    local steamID = ply:SteamID()
    for _, activeMission in pairs(self.Missions.active) do
        if activeMission.player == steamID then
            return false, "You already have an active mission"
        end
    end
    
    -- Check faction requirement
    if mission.faction ~= "Any" then
        local playerFaction = self:GetPlayerFaction(ply)
        if playerFaction ~= mission.faction then
            return false, "This mission is only available for " .. mission.faction
        end
    end
    
    -- Move mission to active
    mission.player = steamID
    mission.playerName = ply:Nick()
    mission.acceptedAt = os.time()
    mission.expiresAt = os.time() + mission.timeLimit
    
    self.Missions.active[missionID] = mission
    self.Missions.available[missionID] = nil
    
    self:SaveMissions()
    
    self:Log(string.format("%s accepted mission #%d (%s)", ply:Nick(), missionID, mission.title))
    
    return true, mission
end

-- Complete mission objective
function GM:UpdateMissionProgress(ply, objectiveIndex, progress)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    
    -- Find player's active mission
    for missionID, mission in pairs(self.Missions.active) do
        if mission.player == steamID then
            local objective = mission.objectives[objectiveIndex]
            if objective then
                objective.progress = math.min(objective.progress + progress, objective.target)
                
                if objective.progress >= objective.target then
                    objective.completed = true
                end
                
                -- Check if all objectives are completed
                local allCompleted = true
                for _, obj in ipairs(mission.objectives) do
                    if not obj.completed then
                        allCompleted = false
                        break
                    end
                end
                
                if allCompleted then
                    self:CompleteMission(ply, missionID)
                end
                
                self:SaveMissions()
                return true
            end
        end
    end
    
    return false
end

-- Complete a mission
function GM:CompleteMission(ply, missionID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local mission = self.Missions.active[missionID]
    if not mission then
        return false, "Mission not found"
    end
    
    if mission.player ~= ply:SteamID() then
        return false, "This is not your mission"
    end
    
    -- Award rewards
    if mission.rewards.credits then
        self:AddPlayerCredits(ply, mission.rewards.credits)
    end
    
    if mission.rewards.reputation then
        -- Reputation system will be added in next section
        -- For now, just log it
        self:Log(string.format("Mission awarded %d reputation to %s", 
            mission.rewards.reputation, ply:Nick()))
    end
    
    -- Move to completed
    mission.completedAt = os.time()
    self.Missions.completed[missionID] = mission
    self.Missions.active[missionID] = nil
    
    self:SaveMissions()
    
    self:Notify(ply, string.format("Mission completed! Rewards: %s credits, %d reputation",
        self:FormatCredits(mission.rewards.credits), mission.rewards.reputation), NOTIFY_GENERIC)
    
    self:Log(string.format("%s completed mission #%d (%s)", ply:Nick(), missionID, mission.title))
    
    return true, mission
end

-- Get player's active mission
function GM:GetPlayerMission(ply)
    if not self:IsValidPlayer(ply) then
        return nil
    end
    
    local steamID = ply:SteamID()
    
    for missionID, mission in pairs(self.Missions.active) do
        if mission.player == steamID then
            return mission
        end
    end
    
    return nil
end

-- Commands

-- List available missions
GM:RegisterCommand("missions", function(ply, args)
    local availableMissions = GAMEMODE.Missions.available
    
    if table.Count(availableMissions) == 0 then
        GAMEMODE:Notify(ply, "No missions currently available", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== AVAILABLE MISSIONS ===")
    for id, mission in pairs(availableMissions) do
        ply:ChatPrint(string.format("#%d | %s [%s] - Difficulty: %d/5",
            id, mission.title, mission.typeName, mission.difficulty))
        ply:ChatPrint(string.format("  Rewards: %s credits, %d reputation",
            GAMEMODE:FormatCredits(mission.rewards.credits), mission.rewards.reputation))
    end
    ply:ChatPrint("Use /acceptmission <ID> to accept a mission")
    ply:ChatPrint("=========================")
end, false, "View available missions")

-- Accept mission command
GM:RegisterCommand("acceptmission", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /acceptmission <missionID>", NOTIFY_ERROR)
        return
    end
    
    local missionID = tonumber(args[1])
    if not missionID then
        GAMEMODE:Notify(ply, "Invalid mission ID", NOTIFY_ERROR)
        return
    end
    
    local success, result = GAMEMODE:AcceptMission(ply, missionID)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Accepted mission: %s", result.title), NOTIFY_GENERIC)
        ply:ChatPrint("=== MISSION BRIEFING ===")
        ply:ChatPrint("Title: " .. result.title)
        ply:ChatPrint("Description: " .. result.description)
        ply:ChatPrint("Objectives:")
        for i, obj in ipairs(result.objectives) do
            ply:ChatPrint(string.format("  %d. %s", i, obj.description))
        end
        ply:ChatPrint("Use /checkmission to view progress")
        ply:ChatPrint("=======================")
    else
        GAMEMODE:Notify(ply, "Error: " .. result, NOTIFY_ERROR)
    end
end, false, "Accept a mission")

-- Check mission progress
GM:RegisterCommand("checkmission", function(ply, args)
    local mission = GAMEMODE:GetPlayerMission(ply)
    
    if not mission then
        GAMEMODE:Notify(ply, "You do not have an active mission", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== ACTIVE MISSION ===")
    ply:ChatPrint("Title: " .. mission.title)
    ply:ChatPrint("Type: " .. mission.typeName)
    ply:ChatPrint("Objectives:")
    
    for i, obj in ipairs(mission.objectives) do
        local status = obj.completed and "[✓]" or "[ ]"
        ply:ChatPrint(string.format("  %s %d. %s (%d/%d)",
            status, i, obj.description, obj.progress, obj.target))
    end
    
    local timeRemaining = mission.expiresAt - os.time()
    ply:ChatPrint(string.format("Time Remaining: %s", GAMEMODE:FormatTime(math.max(0, timeRemaining))))
    ply:ChatPrint("=====================")
end, false, "Check your active mission progress")

-- Abandon mission
GM:RegisterCommand("abandonmission", function(ply, args)
    local mission = GAMEMODE:GetPlayerMission(ply)
    
    if not mission then
        GAMEMODE:Notify(ply, "You do not have an active mission", NOTIFY_HINT)
        return
    end
    
    -- Return mission to available
    for missionID, activeMission in pairs(GAMEMODE.Missions.active) do
        if activeMission.player == ply:SteamID() then
            activeMission.player = nil
            activeMission.playerName = nil
            activeMission.acceptedAt = nil
            activeMission.expiresAt = nil
            
            GAMEMODE.Missions.available[missionID] = activeMission
            GAMEMODE.Missions.active[missionID] = nil
            break
        end
    end
    
    GAMEMODE:SaveMissions()
    GAMEMODE:Notify(ply, "Mission abandoned", NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s abandoned mission: %s", ply:Nick(), mission.title))
end, false, "Abandon your active mission")

-- Admin: Generate new missions
GM:RegisterCommand("generatemissions", function(ply, args)
    local count = 5
    if #args > 0 then
        count = tonumber(args[1]) or 5
    end
    
    count = math.Clamp(count, 1, 20)
    
    GAMEMODE:GenerateRandomMissions(count)
    GAMEMODE:Notify(ply, string.format("Generated %d new missions", count), NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s generated %d new missions", ply:Nick(), count))
end, true, "Generate new random missions (admin only)")

-- Load missions on server init
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_LoadMissions", function()
        GAMEMODE:LoadMissions()
    end)
    
    -- Auto-save missions periodically
    timer.Create("ProjectSovereign_MissionAutoSave", 300, 0, function()
        GAMEMODE:SaveMissions()
    end)
    
    -- Check for expired missions
    timer.Create("ProjectSovereign_MissionExpireCheck", 60, 0, function()
        for missionID, mission in pairs(GAMEMODE.Missions.active) do
            if mission.expiresAt and os.time() >= mission.expiresAt then
                -- Return to available
                mission.player = nil
                mission.playerName = nil
                mission.acceptedAt = nil
                mission.expiresAt = nil
                
                GAMEMODE.Missions.available[missionID] = mission
                GAMEMODE.Missions.active[missionID] = nil
                
                GAMEMODE:Log(string.format("Mission #%d (%s) expired", missionID, mission.title))
            end
        end
    end)
end
