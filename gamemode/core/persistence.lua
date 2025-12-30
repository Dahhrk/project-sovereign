--[[
    Persistence System
    Handles saving and loading player data
]]--

-- Initialize player data structure
local function InitializePlayerData(ply)
    ply.PlayerData = ply.PlayerData or {
        credits = GAMEMODE:GetConfig("StartingCredits"),
        playtime = 0,
        firstJoin = os.time(),
        lastSeen = os.time(),
        totalDeaths = 0,
        totalKills = 0
    }
end

-- Get the file path for player data
local function GetPlayerDataPath(steamID)
    -- Sanitize SteamID for file name (replace colons)
    local sanitized = string.gsub(steamID, ":", "_")
    return string.format("project_sovereign/players/%s.txt", sanitized)
end

-- Save a player's data to disk
function GM:SavePlayerData(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        self:ErrorLog("Attempted to save data for invalid player")
        return false
    end
    
    InitializePlayerData(ply)
    
    local steamID = ply:SteamID()
    local data = {
        steamID = steamID,
        name = ply:Nick(),
        faction = ply.Faction or self:GetConfig("DefaultFaction"),
        rank = ply.Rank or self:GetConfig("DefaultRank"),
        credits = ply.PlayerData.credits or self:GetConfig("StartingCredits"),
        playtime = ply.PlayerData.playtime or 0,
        firstJoin = ply.PlayerData.firstJoin or os.time(),
        lastSeen = os.time(),
        totalDeaths = ply.PlayerData.totalDeaths or 0,
        totalKills = ply.PlayerData.totalKills or 0
    }
    
    local json = util.TableToJSON(data, true)
    
    if not json then
        self:ErrorLog("Failed to serialize player data for " .. ply:Nick())
        return false
    end
    
    -- Ensure directory exists
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/players")
    
    -- Write to file
    local filePath = GetPlayerDataPath(steamID)
    file.Write(filePath, json)
    
    self:DebugLog(string.format("Saved data for %s (%s)", ply:Nick(), steamID))
    
    return true
end

-- Load a player's data from disk
function GM:LoadPlayerData(ply)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        self:ErrorLog("Attempted to load data for invalid player")
        return false
    end
    
    local steamID = ply:SteamID()
    local filePath = GetPlayerDataPath(steamID)
    
    -- Check if file exists
    if not file.Exists(filePath, "DATA") then
        self:Log(string.format("No saved data for %s (%s), using defaults", ply:Nick(), steamID))
        InitializePlayerData(ply)
        
        -- Set default faction
        ply.Faction = self:GetConfig("DefaultFaction")
        ply.Rank = self:GetConfig("DefaultRank")
        
        return true
    end
    
    -- Read file
    local fileData = file.Read(filePath, "DATA")
    
    if not fileData then
        self:ErrorLog("Failed to read player data file for " .. ply:Nick())
        InitializePlayerData(ply)
        return false
    end
    
    -- Parse JSON
    local data = util.JSONToTable(fileData)
    
    if not data then
        self:ErrorLog("Failed to parse player data for " .. ply:Nick())
        InitializePlayerData(ply)
        return false
    end
    
    -- Apply loaded data
    ply.Faction = data.faction or self:GetConfig("DefaultFaction")
    ply.Rank = data.rank or self:GetConfig("DefaultRank")
    
    ply.PlayerData = {
        credits = data.credits or self:GetConfig("StartingCredits"),
        playtime = data.playtime or 0,
        firstJoin = data.firstJoin or os.time(),
        lastSeen = data.lastSeen or os.time(),
        totalDeaths = data.totalDeaths or 0,
        totalKills = data.totalKills or 0
    }
    
    self:Log(string.format("Loaded data for %s (%s) - Faction: %s, Rank: %s, Credits: %d", 
        ply:Nick(), steamID, ply.Faction, ply.Rank, ply.PlayerData.credits))
    
    return true
end

-- Auto-save player data periodically
if SERVER then
    timer.Create("ProjectSovereign_AutoSave", GAMEMODE:GetConfig("AutoSaveInterval") or 300, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            GAMEMODE:SavePlayerData(ply)
        end
        
        GAMEMODE:DebugLog("Auto-saved all player data")
    end)
    
    -- Save on disconnect
    hook.Add("PlayerDisconnected", "ProjectSovereign_SaveOnDisconnect", function(ply)
        GAMEMODE:SavePlayerData(ply)
        GAMEMODE:Log(string.format("Player %s disconnected, data saved", ply:Nick()))
    end)
    
    -- Load on connect
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_LoadOnConnect", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                GAMEMODE:LoadPlayerData(ply)
            end
        end)
    end)
    
    -- Track playtime
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_TrackPlaytime", function(ply)
        ply.JoinTime = CurTime()
    end)
    
    hook.Add("PlayerDisconnected", "ProjectSovereign_UpdatePlaytime", function(ply)
        if ply.JoinTime and ply.PlayerData then
            local sessionTime = CurTime() - ply.JoinTime
            ply.PlayerData.playtime = (ply.PlayerData.playtime or 0) + sessionTime
        end
    end)
    
    -- Track kills and deaths
    hook.Add("PlayerDeath", "ProjectSovereign_TrackDeaths", function(victim, inflictor, attacker)
        if IsValid(victim) and victim:IsPlayer() then
            InitializePlayerData(victim)
            victim.PlayerData.totalDeaths = (victim.PlayerData.totalDeaths or 0) + 1
        end
        
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            InitializePlayerData(attacker)
            attacker.PlayerData.totalKills = (attacker.PlayerData.totalKills or 0) + 1
        end
    end)
end

-- Helper functions for player data access

function GM:GetPlayerCredits(ply)
    if not self:IsValidPlayer(ply) then return 0 end
    InitializePlayerData(ply)
    return ply.PlayerData.credits or 0
end

function GM:SetPlayerCredits(ply, amount)
    if not self:IsValidPlayer(ply) then return false end
    InitializePlayerData(ply)
    
    amount = self:Clamp(amount, 0, self:GetConfig("MaxCredits"))
    ply.PlayerData.credits = amount
    
    return true
end

function GM:AddPlayerCredits(ply, amount)
    if not self:IsValidPlayer(ply) then return false end
    
    local current = self:GetPlayerCredits(ply)
    return self:SetPlayerCredits(ply, current + amount)
end

function GM:RemovePlayerCredits(ply, amount)
    if not self:IsValidPlayer(ply) then return false end
    
    local current = self:GetPlayerCredits(ply)
    if current < amount then
        return false
    end
    
    return self:SetPlayerCredits(ply, current - amount)
end

function GM:CanAfford(ply, amount)
    return self:GetPlayerCredits(ply) >= amount
end
