--[[
    Roleplay Enforcement System
    Handles faction-based loadouts and role assignments
]]--

-- Apply a loadout to a player based on their faction and rank
function GM:ApplyLoadout(ply)
    if not SERVER then return end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local faction = self:GetPlayerFaction(ply)
    local rank = self:GetPlayerRank(ply)
    
    if not faction or not rank then
        self:ErrorLog("Cannot apply loadout - player has no faction or rank")
        return false
    end
    
    local loadout = self:GetLoadout(faction, rank)
    
    if not loadout then
        self:ErrorLog(string.format("No loadout found for %s - %s", faction, rank))
        return false
    end
    
    -- Strip all weapons
    ply:StripWeapons()
    
    -- Give weapons from loadout
    if loadout.weapons then
        for _, weapon in ipairs(loadout.weapons) do
            ply:Give(weapon)
        end
    end
    
    -- Set health
    if loadout.health then
        ply:SetHealth(loadout.health)
        ply:SetMaxHealth(loadout.health)
    end
    
    -- Set armor
    if loadout.armor then
        ply:SetArmor(loadout.armor)
    end
    
    self:DebugLog(string.format("Applied loadout to %s (%s - %s)", ply:Nick(), faction, rank))
    
    return true
end

-- Enforce faction role on player
function GM:EnforceFactionRole(ply)
    if not SERVER then return end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local faction = self:GetPlayerFaction(ply)
    
    -- If player has no faction or is using default, check whitelist
    if not faction or faction == self:GetConfig("DefaultFaction") then
        local whitelists = self:GetPlayerWhitelists(ply)
        
        -- If player has whitelists available, don't enforce default
        if table.Count(whitelists) > 0 then
            self:Notify(ply, "You have faction whitelists available. Use the faction menu to select your faction.", NOTIFY_HINT)
            return true
        end
        
        -- Otherwise, enforce default civilian role
        faction = self:GetConfig("DefaultFaction")
        local rank = self:GetConfig("DefaultRank")
        
        self:SetPlayerFaction(ply, faction, rank)
        self:Notify(ply, "You are currently a civilian. Contact an admin for faction whitelist.", NOTIFY_HINT)
    end
    
    return true
end

-- Apply team color based on faction
function GM:SetPlayerTeamColor(ply)
    if not self:IsValidPlayer(ply) then
        return
    end
    
    local faction = self:GetPlayerFaction(ply)
    
    if not faction or not self.Factions[faction] then
        return
    end
    
    local factionData = self.Factions[faction]
    
    if factionData.color then
        ply:SetPlayerColor(Vector(
            factionData.color.r / 255,
            factionData.color.g / 255,
            factionData.color.b / 255
        ))
    end
end

-- Get formatted name with rank prefix
function GM:GetFormattedName(ply)
    if not self:IsValidPlayer(ply) then
        return "Unknown"
    end
    
    local name = ply:Nick()
    
    if self:GetConfig("ShowRankPrefixes") then
        local rank = self:GetPlayerRank(ply)
        if rank then
            name = string.format("[%s] %s", rank, name)
        end
    end
    
    return name
end

-- Check if two players are in the same faction
function GM:AreSameFaction(ply1, ply2)
    if not self:IsValidPlayer(ply1) or not self:IsValidPlayer(ply2) then
        return false
    end
    
    return self:GetPlayerFaction(ply1) == self:GetPlayerFaction(ply2)
end

-- Check if two factions are hostile
function GM:AreFactionsHostile(faction1, faction2)
    -- Define faction relationships
    local hostileRelations = {
        ["Republic"] = {"CIS", "Sith"},
        ["CIS"] = {"Republic", "Jedi"},
        ["Jedi"] = {"Sith", "CIS"},
        ["Sith"] = {"Jedi", "Republic"}
    }
    
    if not faction1 or not faction2 then
        return false
    end
    
    if faction1 == faction2 then
        return false
    end
    
    if hostileRelations[faction1] then
        for _, hostile in ipairs(hostileRelations[faction1]) do
            if hostile == faction2 then
                return true
            end
        end
    end
    
    return false
end

-- Check if PvP is allowed between two players
function GM:CanPvP(attacker, victim)
    if not self:GetConfig("PvPEnabled") then
        return false
    end
    
    if not self:IsValidPlayer(attacker) or not self:IsValidPlayer(victim) then
        return false
    end
    
    -- Check friendly fire
    if self:AreSameFaction(attacker, victim) and not self:GetConfig("FriendlyFire") then
        return false
    end
    
    return true
end

-- Server-side hooks
if SERVER then
    -- Apply loadout on spawn (prevents default loadout)
    hook.Add("PlayerLoadout", "ProjectSovereign_ApplyLoadout", function(ply)
        GAMEMODE:ApplyLoadout(ply)
        return true -- Prevent default loadout from being applied
    end)
    
    -- Enforce faction roles on spawn
    hook.Add("PlayerSpawn", "ProjectSovereign_EnforceRole", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                GAMEMODE:EnforceFactionRole(ply)
                GAMEMODE:SetPlayerTeamColor(ply)
            end
        end)
    end)
    
    -- Prevent friendly fire if disabled
    hook.Add("PlayerShouldTakeDamage", "ProjectSovereign_FriendlyFire", function(victim, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            return true
        end
        
        if not IsValid(victim) or not victim:IsPlayer() then
            return true
        end
        
        return GAMEMODE:CanPvP(attacker, victim)
    end)
    
    -- Set player color on spawn
    hook.Add("PlayerSpawn", "ProjectSovereign_SetColor", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                GAMEMODE:SetPlayerTeamColor(ply)
            end
        end)
    end)
end
