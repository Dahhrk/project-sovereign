--[[
    Core Configuration
    Configuration constants and helper functions
]]--

-- Configuration version for compatibility checking
GM.ConfigVersion = "1.0.0"

-- Default configuration values (can be overridden by server_config.lua)
GM.DefaultConfig = {
    -- Debug settings
    EnableDebug = false,
    VerboseLogging = false,
    
    -- Gameplay settings
    StartingCredits = 5000,
    MaxCredits = 999999999,
    
    -- Persistence settings
    AutoSaveInterval = 300,
    
    -- Spawn settings
    SpawnProtectionTime = 5,
    
    -- Combat settings
    FriendlyFire = false,
    PvPEnabled = true,
    
    -- Roleplay settings
    EnforceWhitelist = true,
    DefaultFaction = "Civilian",
    DefaultRank = "Citizen",
}

-- Validate configuration values
function GM:ValidateConfig()
    local config = self.Config or {}
    
    -- Check for required config values
    local requiredKeys = {
        "StartingCredits",
        "DefaultFaction",
        "DefaultRank",
        "EnforceWhitelist"
    }
    
    for _, key in ipairs(requiredKeys) do
        if config[key] == nil then
            self:ErrorLog(string.format("Missing required config key: %s", key))
            return false
        end
    end
    
    -- Validate numeric ranges
    if config.StartingCredits and config.StartingCredits < 0 then
        self:ErrorLog("StartingCredits must be >= 0")
        return false
    end
    
    if config.AutoSaveInterval and config.AutoSaveInterval < 60 then
        self:Log("Warning: AutoSaveInterval is very low (< 60 seconds)", "WARN")
    end
    
    if config.SpawnProtectionTime and config.SpawnProtectionTime < 0 then
        self:ErrorLog("SpawnProtectionTime must be >= 0")
        return false
    end
    
    -- Validate faction/rank existence
    if not self:IsValidFaction(config.DefaultFaction) then
        self:ErrorLog(string.format("Invalid DefaultFaction: %s", config.DefaultFaction))
        return false
    end
    
    if not self:IsValidRank(config.DefaultFaction, config.DefaultRank) then
        self:ErrorLog(string.format("Invalid DefaultRank for faction %s: %s", 
            config.DefaultFaction, config.DefaultRank))
        return false
    end
    
    self:DebugLog("Configuration validated successfully")
    return true
end

-- Get configuration value with fallback to default
function GM:GetConfigSafe(key, fallback)
    local value = self:GetConfig(key)
    
    if value ~= nil then
        return value
    end
    
    -- Try default config
    if self.DefaultConfig[key] ~= nil then
        return self.DefaultConfig[key]
    end
    
    return fallback
end

-- Set multiple config values at once
function GM:SetConfigTable(configTable)
    if not configTable or type(configTable) ~= "table" then
        return false
    end
    
    for key, value in pairs(configTable) do
        self:SetConfig(key, value)
    end
    
    return true
end

-- Print current configuration (debug)
function GM:PrintConfig()
    if not self.Config then
        print("No configuration loaded")
        return
    end
    
    print("=== Current Configuration ===")
    
    for key, value in pairs(self.Config) do
        print(string.format("  %s = %s", key, tostring(value)))
    end
    
    print("============================")
end

-- Configuration loaded hook
hook.Add("Initialize", "ProjectSovereign_ConfigInit", function()
    if SERVER then
        -- Validate config after all files are loaded
        timer.Simple(1, function()
            if GAMEMODE and GAMEMODE.ValidateConfig then
                GAMEMODE:ValidateConfig()
            end
        end)
    end
end)

print("Core config (config.lua) loaded")
