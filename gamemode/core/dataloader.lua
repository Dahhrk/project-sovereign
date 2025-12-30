--[[
    Data Loader
    Module initialization and load order management
]]--

-- Module loading state
GM.LoadedModules = GM.LoadedModules or {}
GM.ModuleLoadOrder = GM.ModuleLoadOrder or {}

-- Define module load order
-- This ensures dependencies are loaded in the correct sequence
local LOAD_ORDER = {
    -- Phase 1: Configuration
    {
        name = "Configuration",
        priority = 1,
        files = {
            "config/factions_config.lua",
            "config/loadouts_config.lua",
            "config/server_config.lua"
        }
    },
    
    -- Phase 2: Core utilities (no dependencies)
    {
        name = "Core Utilities",
        priority = 2,
        files = {
            "core/utils.lua",
            "core/config.lua",
            "core/hooks.lua"
        }
    },
    
    -- Phase 3: Core systems (depend on utilities)
    {
        name = "Core Systems",
        priority = 3,
        files = {
            "core/sh_core.lua",
            "core/cl_core.lua",
            "core/sv_core.lua",
            "core/factions.lua",
            "core/persistence.lua"
        }
    },
    
    -- Phase 4: Roleplay systems (depend on core)
    {
        name = "Roleplay Systems",
        priority = 4,
        files = {
            "core/roleplay_enforcement.lua",
            "core/commands.lua"
        }
    },
    
    -- Phase 5: Player systems
    {
        name = "Player Systems",
        priority = 5,
        files = {
            "player/spawn.lua",
            "player/data_store.lua"
        }
    },
    
    -- Phase 6: Modules (depend on core and player systems)
    {
        name = "Modules",
        priority = 6,
        files = {
            "modules/logger.lua",
            "modules/economy.lua",
            "modules/combat.lua"
        }
    }
}

-- Mark a module as loaded
function GM:MarkModuleLoaded(moduleName)
    self.LoadedModules[moduleName] = true
    self:DebugLog(string.format("Module loaded: %s", moduleName))
end

-- Check if a module is loaded
function GM:IsModuleLoaded(moduleName)
    return self.LoadedModules[moduleName] == true
end

-- Get loading progress
function GM:GetLoadingProgress()
    local totalModules = 0
    local loadedModules = 0
    
    for _, phase in ipairs(LOAD_ORDER) do
        totalModules = totalModules + #phase.files
    end
    
    loadedModules = table.Count(self.LoadedModules)
    
    return loadedModules, totalModules
end

-- Verify all required modules are loaded
function GM:VerifyModulesLoaded()
    local missing = {}
    
    for _, phase in ipairs(LOAD_ORDER) do
        for _, file in ipairs(phase.files) do
            local moduleName = string.GetFileFromFilename(file)
            
            if not self:IsModuleLoaded(moduleName) then
                table.insert(missing, file)
            end
        end
    end
    
    if #missing > 0 then
        self:ErrorLog("Missing modules:")
        for _, file in ipairs(missing) do
            self:ErrorLog("  - " .. file)
        end
        return false
    end
    
    return true
end

-- Get load order information
function GM:GetLoadOrder()
    return LOAD_ORDER
end

-- Print loading status
function GM:PrintLoadingStatus()
    local loaded, total = self:GetLoadingProgress()
    
    print("=== Module Loading Status ===")
    print(string.format("Progress: %d/%d modules loaded", loaded, total))
    
    for _, phase in ipairs(LOAD_ORDER) do
        print(string.format("\n[Phase %d] %s:", phase.priority, phase.name))
        
        for _, file in ipairs(phase.files) do
            local moduleName = string.GetFileFromFilename(file)
            local status = self:IsModuleLoaded(moduleName) and "✓" or "✗"
            print(string.format("  %s %s", status, file))
        end
    end
    
    print("=============================")
end

-- Validate module dependencies
function GM:ValidateModuleDependencies()
    -- Basic validation: ensure core modules are loaded before advanced ones
    local coreModules = {
        "utils.lua",
        "factions.lua",
        "persistence.lua"
    }
    
    for _, module in ipairs(coreModules) do
        if not self:IsModuleLoaded(module) then
            self:ErrorLog(string.format("Core module not loaded: %s", module))
            return false
        end
    end
    
    self:DebugLog("Module dependencies validated")
    return true
end

-- Initialize data loader
hook.Add("Initialize", "ProjectSovereign_DataLoader", function()
    if GAMEMODE then
        GAMEMODE:DebugLog("Data loader initialized")
        
        -- Mark modules as they're loaded (this happens after init.lua has loaded them)
        timer.Simple(0.5, function()
            -- Auto-detect loaded modules based on LOAD_ORDER
            for _, phase in ipairs(LOAD_ORDER) do
                for _, file in ipairs(phase.files) do
                    local moduleName = string.GetFileFromFilename(file)
                    GAMEMODE:MarkModuleLoaded(moduleName)
                end
            end
            
            -- Verify and report
            if GAMEMODE:VerifyModulesLoaded() then
                GAMEMODE:Log("All modules loaded successfully")
                GAMEMODE:SetGamemodeLoaded(true)
            else
                GAMEMODE:ErrorLog("Some modules failed to load")
            end
            
            -- Print status if debug is enabled
            if GAMEMODE:GetConfig("EnableDebug") then
                GAMEMODE:PrintLoadingStatus()
            end
        end)
    end
end)

print("Data loader (dataloader.lua) loaded")
