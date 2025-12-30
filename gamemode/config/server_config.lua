--[[
    Server Configuration
    General gamemode and server settings
]]--

GM.Config = GM.Config or {}

GM.Config = {
    -- Gamemode Information
    GamemodeName = "Project Sovereign",
    GamemodeVersion = "1.0.0 - Phase 1",
    GamemodeAuthor = "Dahhrk",
    
    -- Server Settings
    MaxPlayers = 128,
    TickRate = 66,
    
    -- Persistence Settings
    AutoSaveInterval = 300, -- Auto-save player data every 5 minutes (in seconds)
    DataSaveMethod = "SQLite", -- SQLite or MySQL (MySQL not yet implemented)
    
    -- Economy Settings
    StartingCredits = 5000,
    MaxCredits = 999999999,
    
    -- Spawn Settings
    DefaultSpawnLocation = Vector(0, 0, 0),
    DefaultSpawnAngles = Angle(0, 0, 0),
    SpawnProtectionTime = 5, -- Seconds of spawn protection
    
    -- Combat Settings
    FriendlyFire = false,
    PvPEnabled = true,
    
    -- Roleplay Settings
    EnforceWhitelist = true,
    DefaultFaction = "Civilian",
    DefaultRank = "Citizen",
    RequireRPName = false,
    
    -- Logging Settings
    EnableLogging = true,
    LogAdminActions = true,
    LogPlayerActions = true,
    LogCombat = true,
    
    -- Admin Settings
    AdminChatTag = "[ADMIN]",
    ModeratorChatTag = "[MOD]",
    
    -- UI Settings
    ShowFactionColors = true,
    ShowRankPrefixes = true,
    
    -- Performance Settings
    EnableDebug = false,
    VerboseLogging = false
}

-- Helper function to get config value
function GM:GetConfig(key)
    return self.Config[key]
end

-- Helper function to set config value (server-side only)
function GM:SetConfig(key, value)
    if SERVER then
        self.Config[key] = value
    end
end
