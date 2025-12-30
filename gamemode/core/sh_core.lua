--[[
    Shared Core
    Core functionality shared between client and server
]]--

-- Notification types (matching GMod's NOTIFY_* constants)
NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_UNDO = 2
NOTIFY_HINT = 3
NOTIFY_CLEANUP = 4

-- Initialize core shared data structures
GM.SharedData = GM.SharedData or {}

-- Shared utility to check if gamemode is fully loaded
function GM:IsGamemodeLoaded()
    return self.GamemodeLoaded or false
end

-- Mark gamemode as loaded (called after all systems initialize)
function GM:SetGamemodeLoaded(loaded)
    self.GamemodeLoaded = loaded
    
    if loaded then
        self:Log("Gamemode fully loaded and ready")
    end
end

-- Shared validation for faction/rank combinations
function GM:ValidateFactionRankCombo(faction, rank)
    if not self:IsValidFaction(faction) then
        return false, "Invalid faction"
    end
    
    if not self:IsValidRank(faction, rank) then
        return false, "Invalid rank for faction"
    end
    
    return true, "Valid"
end

-- Get faction display name
function GM:GetFactionDisplayName(faction)
    if not self:IsValidFaction(faction) then
        return "Unknown"
    end
    
    return self.Factions[faction].name or faction
end

-- Get faction color
function GM:GetFactionColor(faction)
    if not self:IsValidFaction(faction) then
        return Color(255, 255, 255)
    end
    
    return self.Factions[faction].color or Color(255, 255, 255)
end

-- Get rank display with index
function GM:GetRankIndex(faction, rank)
    if not self:IsValidFaction(faction) then
        return 0
    end
    
    local ranks = self.Factions[faction].ranks
    
    for i, r in ipairs(ranks) do
        if r == rank then
            return i
        end
    end
    
    return 0
end

-- Compare ranks (returns true if rank1 is higher than rank2)
function GM:IsRankHigher(faction, rank1, rank2)
    local index1 = self:GetRankIndex(faction, rank1)
    local index2 = self:GetRankIndex(faction, rank2)
    
    return index1 > index2
end

-- Shared hook for faction changes
hook.Add("Initialize", "ProjectSovereign_SharedInit", function()
    if GAMEMODE then
        GAMEMODE:Log("Shared core initialized")
    end
end)

print("Shared core (sh_core.lua) loaded")
