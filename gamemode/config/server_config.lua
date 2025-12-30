--[[
    Server Configuration
    General gamemode and server settings
]]--

GM.Config = GM.Config or {}

GM.Config = {
    -- Gamemode Information
    GamemodeName = "Project Sovereign",
    GamemodeVersion = "2.0.0 - Phase 2",
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
    TransactionTaxRate = 0.05, -- 5% tax on transfers
    PurchaseTaxRate = 0.10, -- 10% tax on purchases
    TaxEnabled = true,
    
    -- Faction Settings
    StartingFactionBudget = 50000,
    
    -- Inventory Settings
    DefaultInventoryWeight = 100, -- Default max weight in kg
    
    -- Mission Settings
    MissionExpirationTime = 1800, -- 30 minutes in seconds
    DefaultMissionRewards = {
        Combat = {credits = 1000, reputation = 50},
        Economy = {credits = 1500, reputation = 30},
        Exploration = {credits = 800, reputation = 40}
    },
    
    -- Event Settings
    EventCheckInterval = 60, -- Check for events every minute
    
    -- Reputation Settings
    ReputationMin = -10000,
    ReputationMax = 10000,
    
    -- Progression Settings
    SkillPointsPerLevel = 1,
    SkillPointsPerPromotion = 1,
    
    -- Analytics Settings
    AnalyticsUpdateInterval = 300, -- Update analytics every 5 minutes
    
    -- Auto-Moderation Settings
    AutoModEnabled = true,
    MaxOffenseHistory = 10, -- Keep last 10 offenses per rule
    
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
