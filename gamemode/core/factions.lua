--[[
    Factions System
    Manages factions, ranks, and whitelist enforcement
]]--

-- Store whitelist data
GM.Whitelist = GM.Whitelist or {}

-- Initialize faction data on player
local function InitializePlayerFaction(ply)
    ply.Faction = ply.Faction or GAMEMODE:GetConfig("DefaultFaction")
    ply.Rank = ply.Rank or GAMEMODE:GetConfig("DefaultRank")
    ply.Whitelisted = ply.Whitelisted or {}
end

-- Add a player to whitelist for a faction
function GM:AddToWhitelist(ply, faction, rank)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not self:IsValidFaction(faction) then
        return false, "Invalid faction: " .. tostring(faction)
    end
    
    if not self:IsValidRank(faction, rank) then
        return false, "Invalid rank for faction " .. faction .. ": " .. tostring(rank)
    end
    
    local steamID = ply:SteamID()
    
    -- Initialize whitelist table for this SteamID if it doesn't exist
    if not self.Whitelist[steamID] then
        self.Whitelist[steamID] = {}
    end
    
    -- Add faction whitelist
    self.Whitelist[steamID][faction] = rank
    
    -- Update player's current whitelist table
    InitializePlayerFaction(ply)
    ply.Whitelisted[faction] = rank
    
    self:Log(string.format("Added %s (%s) to %s whitelist as %s", ply:Nick(), steamID, faction, rank))
    
    -- Save whitelist data
    self:SaveWhitelist()
    
    return true, "Successfully whitelisted"
end

-- Remove a player from whitelist for a faction
function GM:RemoveFromWhitelist(ply, faction)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not self:IsValidFaction(faction) then
        return false, "Invalid faction: " .. tostring(faction)
    end
    
    local steamID = ply:SteamID()
    
    if not self.Whitelist[steamID] or not self.Whitelist[steamID][faction] then
        return false, "Player is not whitelisted for " .. faction
    end
    
    -- Remove from whitelist
    self.Whitelist[steamID][faction] = nil
    
    -- Update player's current whitelist table
    if ply.Whitelisted then
        ply.Whitelisted[faction] = nil
    end
    
    -- If this was their current faction, reset to default
    if ply.Faction == faction then
        ply.Faction = self:GetConfig("DefaultFaction")
        ply.Rank = self:GetConfig("DefaultRank")
    end
    
    self:Log(string.format("Removed %s (%s) from %s whitelist", ply:Nick(), steamID, faction))
    
    -- Save whitelist data
    self:SaveWhitelist()
    
    return true, "Successfully removed from whitelist"
end

-- Check if a player is whitelisted for a faction
function GM:IsWhitelisted(ply, faction)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    
    if self.Whitelist[steamID] and self.Whitelist[steamID][faction] then
        return true, self.Whitelist[steamID][faction]
    end
    
    return false
end

-- Set a player's active faction and rank
function GM:SetPlayerFaction(ply, faction, rank)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not self:IsValidFaction(faction) then
        return false, "Invalid faction: " .. tostring(faction)
    end
    
    -- If whitelist is enforced, check if player is whitelisted
    if self:GetConfig("EnforceWhitelist") then
        local isWhitelisted, whitelistedRank = self:IsWhitelisted(ply, faction)
        
        if not isWhitelisted then
            return false, "Player is not whitelisted for " .. faction
        end
        
        -- If no rank specified, use whitelisted rank
        if not rank then
            rank = whitelistedRank
        end
    end
    
    -- If no rank specified, use default
    if not rank then
        rank = self:GetDefaultRank(faction)
    end
    
    if not self:IsValidRank(faction, rank) then
        return false, "Invalid rank for faction " .. faction .. ": " .. tostring(rank)
    end
    
    -- Set faction and rank
    ply.Faction = faction
    ply.Rank = rank
    
    self:Log(string.format("Set %s's faction to %s (Rank: %s)", ply:Nick(), faction, rank))
    
    -- Apply loadout for the new faction/rank
    if SERVER then
        self:ApplyLoadout(ply)
    end
    
    return true, "Faction set successfully"
end

-- Get a player's current faction
function GM:GetPlayerFaction(ply)
    if not self:IsValidPlayer(ply) then
        return nil
    end
    
    InitializePlayerFaction(ply)
    return ply.Faction
end

-- Get a player's current rank
function GM:GetPlayerRank(ply)
    if not self:IsValidPlayer(ply) then
        return nil
    end
    
    InitializePlayerFaction(ply)
    return ply.Rank
end

-- Get all whitelisted factions for a player
function GM:GetPlayerWhitelists(ply)
    if not self:IsValidPlayer(ply) then
        return {}
    end
    
    local steamID = ply:SteamID()
    return self.Whitelist[steamID] or {}
end

-- Save whitelist to file
function GM:SaveWhitelist()
    if not SERVER then return end
    
    local data = util.TableToJSON(self.Whitelist, true)
    
    if not data then
        self:ErrorLog("Failed to serialize whitelist data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write("project_sovereign/whitelist.txt", data)
    
    self:DebugLog("Whitelist data saved")
    return true
end

-- Load whitelist from file
function GM:LoadWhitelist()
    if not SERVER then return end
    
    if not file.Exists("project_sovereign/whitelist.txt", "DATA") then
        self:Log("No whitelist file found, starting fresh")
        self.Whitelist = {}
        return true
    end
    
    local data = file.Read("project_sovereign/whitelist.txt", "DATA")
    
    if not data then
        self:ErrorLog("Failed to read whitelist file")
        return false
    end
    
    local tbl = util.JSONToTable(data)
    
    if not tbl then
        self:ErrorLog("Failed to parse whitelist data")
        return false
    end
    
    self.Whitelist = tbl
    self:Log("Whitelist data loaded successfully")
    
    return true
end

-- Initialize player faction data when they spawn
if SERVER then
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_InitFaction", function(ply)
        InitializePlayerFaction(ply)
        
        -- Load their whitelist data
        local steamID = ply:SteamID()
        if GAMEMODE.Whitelist[steamID] then
            ply.Whitelisted = GAMEMODE:TableCopy(GAMEMODE.Whitelist[steamID])
        else
            ply.Whitelisted = {}
        end
        
        GAMEMODE:Log(string.format("Player %s connected (Faction: %s, Rank: %s)", 
            ply:Nick(), ply.Faction, ply.Rank))
    end)
end
