--[[
    Custom Hooks Framework
    Framework for registering and managing custom gamemode hooks
]]--

-- Store custom hooks
GM.CustomHooks = GM.CustomHooks or {}

-- Register a custom hook
function GM:RegisterCustomHook(hookName, identifier, callback)
    if not hookName or hookName == "" then
        self:ErrorLog("Invalid hook name")
        return false
    end
    
    if not identifier or identifier == "" then
        self:ErrorLog("Invalid hook identifier")
        return false
    end
    
    if not callback or type(callback) ~= "function" then
        self:ErrorLog("Invalid hook callback")
        return false
    end
    
    -- Initialize hook table if it doesn't exist
    if not self.CustomHooks[hookName] then
        self.CustomHooks[hookName] = {}
    end
    
    -- Register the hook
    self.CustomHooks[hookName][identifier] = callback
    
    self:DebugLog(string.format("Registered custom hook: %s (%s)", hookName, identifier))
    
    return true
end

-- Unregister a custom hook
function GM:UnregisterCustomHook(hookName, identifier)
    if not hookName or not self.CustomHooks[hookName] then
        return false
    end
    
    if not identifier then
        return false
    end
    
    self.CustomHooks[hookName][identifier] = nil
    
    self:DebugLog(string.format("Unregistered custom hook: %s (%s)", hookName, identifier))
    
    return true
end

-- Call a custom hook with arguments
function GM:CallCustomHook(hookName, ...)
    if not hookName or not self.CustomHooks[hookName] then
        return nil
    end
    
    local results = {}
    
    -- Call all registered callbacks for this hook
    for identifier, callback in pairs(self.CustomHooks[hookName]) do
        local success, result = pcall(callback, ...)
        
        if not success then
            self:ErrorLog(string.format("Error in custom hook %s (%s): %s", 
                hookName, identifier, tostring(result)))
        else
            table.insert(results, result)
        end
    end
    
    return results
end

-- Check if a custom hook exists
function GM:HasCustomHook(hookName)
    return self.CustomHooks[hookName] ~= nil and table.Count(self.CustomHooks[hookName]) > 0
end

-- Get all identifiers for a hook
function GM:GetCustomHookIdentifiers(hookName)
    if not hookName or not self.CustomHooks[hookName] then
        return {}
    end
    
    local identifiers = {}
    
    for identifier, _ in pairs(self.CustomHooks[hookName]) do
        table.insert(identifiers, identifier)
    end
    
    return identifiers
end

-- Clear all hooks for a specific hook name
function GM:ClearCustomHooks(hookName)
    if not hookName then
        return false
    end
    
    self.CustomHooks[hookName] = {}
    
    self:DebugLog(string.format("Cleared all custom hooks for: %s", hookName))
    
    return true
end

-- Predefined custom hooks for the gamemode
-- These can be called by other systems

--[[
    ProjectSovereign_FactionChanged(player, newFaction, newRank)
    Called when a player's faction or rank changes
]]--

--[[
    ProjectSovereign_WhitelistAdded(player, faction, rank)
    Called when a player is added to a faction whitelist
]]--

--[[
    ProjectSovereign_WhitelistRemoved(player, faction)
    Called when a player is removed from a faction whitelist
]]--

--[[
    ProjectSovereign_CreditsChanged(player, oldAmount, newAmount)
    Called when a player's credit balance changes
]]--

--[[
    ProjectSovereign_PlayerDataLoaded(player)
    Called when player data is loaded from disk
]]--

--[[
    ProjectSovereign_PlayerDataSaved(player)
    Called when player data is saved to disk
]]--

--[[
    ProjectSovereign_LoadoutApplied(player, faction, rank)
    Called when a loadout is applied to a player
]]--

-- Example custom hook usage:
-- GAMEMODE:RegisterCustomHook("ProjectSovereign_FactionChanged", "MyAddon_FactionListener", function(ply, faction, rank)
--     print(ply:Nick() .. " changed to " .. faction .. " - " .. rank)
-- end)

print("Custom hooks framework (hooks.lua) loaded")
