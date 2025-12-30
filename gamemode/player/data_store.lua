--[[
    Player Data Store
    Additional player data storage and management beyond persistence.lua
]]--

-- Extended player data table
local playerDataStore = {}

-- Initialize data store for a player
local function InitializeDataStore(ply)
    local steamID = ply:SteamID()
    
    if not playerDataStore[steamID] then
        playerDataStore[steamID] = {
            preferences = {
                showHints = true,
                hudScale = 1.0,
                chatTimestamps = true
            },
            achievements = {},
            customData = {}
        }
    end
    
    return playerDataStore[steamID]
end

-- Get player data store
function GM:GetPlayerDataStore(ply)
    if not self:IsValidPlayer(ply) then
        return nil
    end
    
    return InitializeDataStore(ply)
end

-- Set a custom data value for a player
function GM:SetPlayerData(ply, key, value)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local dataStore = InitializeDataStore(ply)
    dataStore.customData[key] = value
    
    return true
end

-- Get a custom data value for a player
function GM:GetPlayerData(ply, key, default)
    if not self:IsValidPlayer(ply) then
        return default
    end
    
    local dataStore = InitializeDataStore(ply)
    
    if dataStore.customData[key] ~= nil then
        return dataStore.customData[key]
    end
    
    return default
end

-- Set a player preference
function GM:SetPlayerPreference(ply, key, value)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local dataStore = InitializeDataStore(ply)
    dataStore.preferences[key] = value
    
    return true
end

-- Get a player preference
function GM:GetPlayerPreference(ply, key, default)
    if not self:IsValidPlayer(ply) then
        return default
    end
    
    local dataStore = InitializeDataStore(ply)
    
    if dataStore.preferences[key] ~= nil then
        return dataStore.preferences[key]
    end
    
    return default
end

-- Award an achievement to a player
function GM:AwardAchievement(ply, achievementID, achievementName)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local dataStore = InitializeDataStore(ply)
    
    if dataStore.achievements[achievementID] then
        return false -- Already has this achievement
    end
    
    dataStore.achievements[achievementID] = {
        name = achievementName,
        timestamp = os.time()
    }
    
    self:Notify(ply, string.format("Achievement Unlocked: %s", achievementName), NOTIFY_GENERIC)
    self:LogPlayerAction(string.format("Unlocked achievement: %s", achievementName), ply)
    
    return true
end

-- Check if player has an achievement
function GM:HasAchievement(ply, achievementID)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local dataStore = InitializeDataStore(ply)
    return dataStore.achievements[achievementID] ~= nil
end

-- Get all achievements for a player
function GM:GetPlayerAchievements(ply)
    if not self:IsValidPlayer(ply) then
        return {}
    end
    
    local dataStore = InitializeDataStore(ply)
    return dataStore.achievements
end

-- Save extended data store to file
function GM:SaveDataStore(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    local dataStore = playerDataStore[steamID]
    
    if not dataStore then
        return false
    end
    
    local json = util.TableToJSON(dataStore, true)
    
    if not json then
        self:ErrorLog("Failed to serialize data store for " .. ply:Nick())
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/datastore")
    
    local sanitized = string.gsub(steamID, ":", "_")
    local filePath = string.format("project_sovereign/datastore/%s.txt", sanitized)
    
    file.Write(filePath, json)
    
    self:DebugLog(string.format("Saved data store for %s", ply:Nick()))
    
    return true
end

-- Load extended data store from file
function GM:LoadDataStore(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    local sanitized = string.gsub(steamID, ":", "_")
    local filePath = string.format("project_sovereign/datastore/%s.txt", sanitized)
    
    if not file.Exists(filePath, "DATA") then
        InitializeDataStore(ply)
        return true
    end
    
    local fileData = file.Read(filePath, "DATA")
    
    if not fileData then
        self:ErrorLog("Failed to read data store for " .. ply:Nick())
        return false
    end
    
    local data = util.JSONToTable(fileData)
    
    if not data then
        self:ErrorLog("Failed to parse data store for " .. ply:Nick())
        return false
    end
    
    playerDataStore[steamID] = data
    
    self:DebugLog(string.format("Loaded data store for %s", ply:Nick()))
    
    return true
end

-- Server-side hooks
if SERVER then
    -- Load data store on connect
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_LoadDataStore", function(ply)
        timer.Simple(1.5, function()
            if IsValid(ply) then
                GAMEMODE:LoadDataStore(ply)
            end
        end)
    end)
    
    -- Save data store on disconnect
    hook.Add("PlayerDisconnected", "ProjectSovereign_SaveDataStore", function(ply)
        GAMEMODE:SaveDataStore(ply)
    end)
    
    -- Auto-save data stores periodically
    timer.Create("ProjectSovereign_DataStoreAutoSave", 600, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            GAMEMODE:SaveDataStore(ply)
        end
        
        GAMEMODE:DebugLog("Auto-saved all data stores")
    end)
end

-- Preferences command
GM:RegisterCommand("preferences", function(ply, args)
    local dataStore = GAMEMODE:GetPlayerDataStore(ply)
    
    if not dataStore then
        GAMEMODE:Notify(ply, "Failed to load preferences", NOTIFY_ERROR)
        return
    end
    
    ply:ChatPrint("=== Your Preferences ===")
    
    for key, value in pairs(dataStore.preferences) do
        ply:ChatPrint(string.format("%s: %s", key, tostring(value)))
    end
end, false, "View your preferences")

-- Achievements command
GM:RegisterCommand("achievements", function(ply, args)
    local achievements = GAMEMODE:GetPlayerAchievements(ply)
    
    ply:ChatPrint("=== Your Achievements ===")
    
    local count = 0
    for id, achievement in pairs(achievements) do
        ply:ChatPrint(string.format("- %s (Unlocked: %s)", 
            achievement.name, os.date("%Y-%m-%d %H:%M:%S", achievement.timestamp)))
        count = count + 1
    end
    
    if count == 0 then
        ply:ChatPrint("No achievements unlocked yet.")
    else
        ply:ChatPrint(string.format("Total: %d achievements", count))
    end
end, false, "View your achievements")
