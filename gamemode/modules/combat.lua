--[[
    Combat Module
    Placeholder combat mechanics for faction conflicts
]]--

-- Combat statistics tracking
local combatStats = {}

-- Initialize combat module
local function InitCombat()
    GAMEMODE:Log("Combat module initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitCombat", InitCombat)
end

-- Get or create combat stats for a player
local function GetCombatStats(ply)
    local steamID = ply:SteamID()
    
    if not combatStats[steamID] then
        combatStats[steamID] = {
            kills = 0,
            deaths = 0,
            assists = 0,
            damageDealt = 0,
            damageTaken = 0,
            killStreak = 0,
            bestStreak = 0
        }
    end
    
    return combatStats[steamID]
end

-- Handle player death
if SERVER then
    hook.Add("PlayerDeath", "ProjectSovereign_CombatDeath", function(victim, inflictor, attacker)
        if not IsValid(victim) or not victim:IsPlayer() then
            return
        end
        
        local victimStats = GetCombatStats(victim)
        victimStats.deaths = victimStats.deaths + 1
        victimStats.killStreak = 0
        
        -- Handle attacker stats
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            local attackerStats = GetCombatStats(attacker)
            attackerStats.kills = attackerStats.kills + 1
            attackerStats.killStreak = attackerStats.killStreak + 1
            
            if attackerStats.killStreak > attackerStats.bestStreak then
                attackerStats.bestStreak = attackerStats.killStreak
            end
            
            -- Notify kill streak
            if attackerStats.killStreak >= 5 then
                GAMEMODE:NotifyAll(string.format("%s is on a %d kill streak!", 
                    attacker:Nick(), attackerStats.killStreak), NOTIFY_HINT)
            end
            
            -- Check for faction combat
            if GAMEMODE:AreFactionsHostile(GAMEMODE:GetPlayerFaction(attacker), GAMEMODE:GetPlayerFaction(victim)) then
                GAMEMODE:DebugLog(string.format("Faction combat: %s killed %s", 
                    attacker:Nick(), victim:Nick()))
            end
        end
    end)
    
    -- Track damage dealt/taken
    hook.Add("EntityTakeDamage", "ProjectSovereign_CombatDamage", function(target, dmg)
        if not IsValid(target) or not target:IsPlayer() then
            return
        end
        
        local attacker = dmg:GetAttacker()
        
        if not IsValid(attacker) or not attacker:IsPlayer() then
            return
        end
        
        if attacker == target then
            return
        end
        
        local damage = dmg:GetDamage()
        local targetStats = GetCombatStats(target)
        local attackerStats = GetCombatStats(attacker)
        
        targetStats.damageTaken = targetStats.damageTaken + damage
        attackerStats.damageDealt = attackerStats.damageDealt + damage
    end)
end

-- Get player combat stats
function GM:GetCombatStats(ply)
    if not self:IsValidPlayer(ply) then
        return nil
    end
    
    return GetCombatStats(ply)
end

-- Reset combat stats for a player
function GM:ResetCombatStats(ply)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local steamID = ply:SteamID()
    combatStats[steamID] = nil
    
    return true
end

-- Combat stats command
GM:RegisterCommand("stats", function(ply, args)
    local target = ply
    
    if #args >= 1 and GAMEMODE:HasPermission(ply, "admin") then
        target = GAMEMODE:FindPlayer(args[1])
        if not target then
            GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
            return
        end
    end
    
    local stats = GetCombatStats(target)
    
    local kd = stats.deaths > 0 and (stats.kills / stats.deaths) or stats.kills
    
    local info = {
        "=== Combat Statistics ===",
        string.format("Player: %s", target:Nick()),
        string.format("Kills: %d", stats.kills),
        string.format("Deaths: %d", stats.deaths),
        string.format("K/D Ratio: %.2f", kd),
        string.format("Current Streak: %d", stats.killStreak),
        string.format("Best Streak: %d", stats.bestStreak),
        string.format("Damage Dealt: %d", math.floor(stats.damageDealt)),
        string.format("Damage Taken: %d", math.floor(stats.damageTaken))
    }
    
    for _, line in ipairs(info) do
        ply:ChatPrint(line)
    end
end, false, "Display combat statistics")

-- Reset stats command (admin only)
GM:RegisterCommand("resetstats", function(ply, args)
    local target = ply
    
    if #args >= 1 then
        target = GAMEMODE:FindPlayer(args[1])
        if not target then
            GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
            return
        end
    end
    
    GAMEMODE:ResetCombatStats(target)
    GAMEMODE:Notify(ply, string.format("Reset combat stats for %s", target:Nick()), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, "Your combat stats have been reset", NOTIFY_HINT)
end, true, "Reset combat statistics")
