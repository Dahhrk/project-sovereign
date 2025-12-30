--[[
    Server Core
    Server-side core functionality and player management
]]--

-- Server-side data
GM.ServerData = GM.ServerData or {}

-- Initialize server-side systems
local function InitializeServer()
    GAMEMODE:Log("Server-side core initialized")
    
    -- Setup auto-save timer
    local saveInterval = GAMEMODE:GetConfig("AutoSaveInterval")
    
    if saveInterval and saveInterval > 0 then
        timer.Create("ProjectSovereign_AutoSave", saveInterval, 0, function()
            GAMEMODE:DebugLog("Running auto-save...")
            
            for _, ply in ipairs(player.GetAll()) do
                GAMEMODE:SavePlayerData(ply)
                GAMEMODE:SaveDataStore(ply)
            end
            
            GAMEMODE:SaveWhitelist()
            
            GAMEMODE:DebugLog("Auto-save completed")
        end)
    end
end

hook.Add("Initialize", "ProjectSovereign_ServerInit", InitializeServer)

-- Handle player initial spawn
hook.Add("PlayerInitialSpawn", "ProjectSovereign_InitialSpawn", function(ply)
    GAMEMODE:Log(string.format("Player connecting: %s (%s)", ply:Nick(), ply:SteamID()))
    
    -- Load player data
    timer.Simple(0.5, function()
        if IsValid(ply) then
            -- Load whitelist for player
            GAMEMODE:LoadPlayerWhitelist(ply)
            
            -- Load player data
            GAMEMODE:LoadPlayerData(ply)
            
            -- Enforce faction role
            GAMEMODE:EnforceFactionRole(ply)
            
            -- Apply loadout
            timer.Simple(0.5, function()
                if IsValid(ply) then
                    GAMEMODE:ApplyLoadout(ply)
                    GAMEMODE:SetPlayerTeamColor(ply)
                end
            end)
            
            -- Welcome message
            GAMEMODE:Notify(ply, "Welcome to " .. GAMEMODE:GetConfig("GamemodeName") .. "!", NOTIFY_HINT)
        end
    end)
end)

-- Handle player loadout after spawn
hook.Add("PlayerLoadout", "ProjectSovereign_Loadout", function(ply)
    -- Prevent default weapons from being given
    -- Our loadout system handles this in roleplay_enforcement.lua
    return true
end)

-- Update playtime on disconnect
hook.Add("PlayerDisconnected", "ProjectSovereign_Disconnect", function(ply)
    GAMEMODE:Log(string.format("Player disconnecting: %s (%s)", ply:Nick(), ply:SteamID()))
    
    -- Update playtime
    if ply.PlayerData and ply.JoinTime then
        local sessionTime = os.time() - ply.JoinTime
        ply.PlayerData.playtime = (ply.PlayerData.playtime or 0) + sessionTime
    end
    
    -- Save all player data
    GAMEMODE:SavePlayerData(ply)
    GAMEMODE:SaveDataStore(ply)
end)

-- Track player join time for playtime calculation
hook.Add("PlayerInitialSpawn", "ProjectSovereign_TrackJoinTime", function(ply)
    ply.JoinTime = os.time()
end)

-- Handle player death for stats tracking
hook.Add("PlayerDeath", "ProjectSovereign_DeathStats", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    -- Update death count
    if victim.PlayerData then
        victim.PlayerData.totalDeaths = (victim.PlayerData.totalDeaths or 0) + 1
    end
    
    -- Update kill count for attacker
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        if attacker.PlayerData then
            attacker.PlayerData.totalKills = (attacker.PlayerData.totalKills or 0) + 1
        end
    end
end)

-- Validate PvP damage based on faction rules
hook.Add("PlayerShouldTakeDamage", "ProjectSovereign_PvPValidation", function(victim, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then
        return true
    end
    
    if not IsValid(attacker) or not attacker:IsPlayer() then
        return true
    end
    
    -- Allow self-damage
    if victim == attacker then
        return true
    end
    
    -- Check if PvP is enabled
    if not GAMEMODE:GetConfig("PvPEnabled") then
        return false
    end
    
    -- Use the CanPvP function from roleplay_enforcement
    if GAMEMODE.CanPvP then
        return GAMEMODE:CanPvP(attacker, victim)
    end
    
    return true
end)

-- Server-side utility: Broadcast to all players
function GM:BroadcastMessage(message, notifyType)
    self:NotifyAll(message, notifyType)
end

-- Server-side utility: Kick player with reason
function GM:KickPlayer(ply, reason)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    self:Log(string.format("Kicking player %s (%s): %s", ply:Nick(), ply:SteamID(), reason or "No reason"))
    
    ply:Kick(reason or "Kicked by admin")
    
    return true
end

-- Server-side utility: Ban player (placeholder - requires external ban system)
function GM:BanPlayer(ply, duration, reason)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    self:Log(string.format("Ban requested for %s (%s): %s", ply:Nick(), ply:SteamID(), reason or "No reason"))
    self:ErrorLog("Ban system not yet implemented - use external ban addon")
    
    -- For now, just kick the player
    self:KickPlayer(ply, reason)
    
    return false
end

-- Admin command: Kick player
GM:RegisterCommand("kick", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /kick <player> [reason]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local reason = table.concat(args, " ", 2) or "Kicked by admin"
    
    GAMEMODE:NotifyAll(string.format("%s was kicked: %s", target:Nick(), reason), NOTIFY_GENERIC)
    GAMEMODE:LogAdminAction(string.format("Kicked %s: %s", target:Nick(), reason), ply)
    
    GAMEMODE:KickPlayer(target, reason)
end, true, "Kick a player from the server")

print("Server core (sv_core.lua) loaded")
