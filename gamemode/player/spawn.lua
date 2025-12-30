--[[
    Player Spawn System
    Handles player spawn logic and spawn points
]]--

-- Spawn locations per faction (can be expanded)
local spawnLocations = {
    ["Republic"] = {
        pos = Vector(0, 0, 100),
        ang = Angle(0, 0, 0)
    },
    ["CIS"] = {
        pos = Vector(500, 0, 100),
        ang = Angle(0, 180, 0)
    },
    ["Jedi"] = {
        pos = Vector(-500, 0, 100),
        ang = Angle(0, 90, 0)
    },
    ["Sith"] = {
        pos = Vector(0, 500, 100),
        ang = Angle(0, 270, 0)
    },
    ["Civilian"] = {
        pos = Vector(0, -500, 100),
        ang = Angle(0, 45, 0)
    }
}

-- Get spawn location for a player based on their faction
function GM:GetPlayerSpawnLocation(ply)
    if not self:IsValidPlayer(ply) then
        return self:GetConfig("DefaultSpawnLocation"), self:GetConfig("DefaultSpawnAngles")
    end
    
    local faction = self:GetPlayerFaction(ply)
    
    if faction and spawnLocations[faction] then
        return spawnLocations[faction].pos, spawnLocations[faction].ang
    end
    
    -- Try to find a spawn point entity
    local spawns = ents.FindByClass("info_player_start")
    
    if #spawns > 0 then
        local spawn = spawns[math.random(1, #spawns)]
        return spawn:GetPos(), spawn:GetAngles()
    end
    
    return self:GetConfig("DefaultSpawnLocation"), self:GetConfig("DefaultSpawnAngles")
end

-- Set spawn location for a faction
function GM:SetFactionSpawnLocation(faction, pos, ang)
    if not self:IsValidFaction(faction) then
        return false
    end
    
    spawnLocations[faction] = {
        pos = pos,
        ang = ang
    }
    
    self:Log(string.format("Set spawn location for %s faction", faction))
    return true
end

-- Handle player spawn
if SERVER then
    hook.Add("PlayerSpawn", "ProjectSovereign_PlayerSpawn", function(ply)
        -- Prevent spawn if player is not ready
        if not ply:IsValid() then
            return
        end
        
        -- Set spawn location
        local pos, ang = GAMEMODE:GetPlayerSpawnLocation(ply)
        
        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply:SetPos(pos)
                ply:SetEyeAngles(ang)
            end
        end)
        
        -- Apply spawn protection
        local protectionTime = GAMEMODE:GetConfig("SpawnProtectionTime")
        
        if protectionTime and protectionTime > 0 then
            ply.SpawnProtected = true
            ply:GodEnable()
            ply:SetRenderMode(RENDERMODE_TRANSALPHA)
            ply:SetColor(Color(255, 255, 255, 200))
            
            timer.Simple(protectionTime, function()
                if IsValid(ply) then
                    ply.SpawnProtected = false
                    ply:GodDisable()
                    ply:SetRenderMode(RENDERMODE_NORMAL)
                    ply:SetColor(Color(255, 255, 255, 255))
                    GAMEMODE:Notify(ply, "Spawn protection expired", NOTIFY_HINT)
                end
            end)
            
            GAMEMODE:Notify(ply, string.format("Spawn protection active for %d seconds", protectionTime), NOTIFY_HINT)
        end
        
        GAMEMODE:DebugLog(string.format("Player %s spawned", ply:Nick()))
    end)
    
    -- Choose player model based on faction
    hook.Add("PlayerSetModel", "ProjectSovereign_PlayerModel", function(ply)
        local faction = GAMEMODE:GetPlayerFaction(ply)
        
        -- Default models per faction (using standard GMod models as placeholders)
        local models = {
            ["Republic"] = "models/player/combine_soldier.mdl",
            ["CIS"] = "models/player/combine_soldier_prisonguard.mdl",
            ["Jedi"] = "models/player/monk.mdl",
            ["Sith"] = "models/player/charple.mdl",
            ["Civilian"] = "models/player/group01/male_01.mdl"
        }
        
        if faction and models[faction] then
            ply:SetModel(models[faction])
        else
            ply:SetModel("models/player/group01/male_01.mdl")
        end
    end)
    
    -- Prevent damage during spawn protection
    hook.Add("EntityTakeDamage", "ProjectSovereign_SpawnProtection", function(target, dmg)
        if IsValid(target) and target:IsPlayer() and target.SpawnProtected then
            dmg:SetDamage(0)
            return true
        end
    end)
end

-- Set spawn command (admin only)
GM:RegisterCommand("setspawn", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /setspawn <faction>", NOTIFY_ERROR)
        return
    end
    
    local faction = args[1]
    
    if not GAMEMODE:IsValidFaction(faction) then
        GAMEMODE:Notify(ply, "Invalid faction: " .. faction, NOTIFY_ERROR)
        return
    end
    
    local pos = ply:GetPos()
    local ang = ply:EyeAngles()
    ang.p = 0 -- Remove pitch
    ang.r = 0 -- Remove roll
    
    GAMEMODE:SetFactionSpawnLocation(faction, pos, ang)
    GAMEMODE:Notify(ply, string.format("Set spawn location for %s faction", faction), NOTIFY_GENERIC)
    GAMEMODE:LogAdminAction(string.format("Set spawn location for %s faction", faction), ply)
end, true, "Set spawn location for a faction")

-- Respawn command (admin only)
GM:RegisterCommand("respawn", function(ply, args)
    local target = ply
    
    if #args >= 1 then
        target = GAMEMODE:FindPlayer(args[1])
        if not target then
            GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
            return
        end
    end
    
    target:Spawn()
    GAMEMODE:Notify(ply, string.format("Respawned %s", target:Nick()), NOTIFY_GENERIC)
    
    if target ~= ply then
        GAMEMODE:Notify(target, "You have been respawned", NOTIFY_HINT)
    end
    
    GAMEMODE:LogAdminAction(string.format("Respawned %s", target:Nick()), ply)
end, true, "Respawn a player")
