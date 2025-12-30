--[[
    Auto-Moderation System Module - Phase 2
    Rule violation warnings and automated punishment system
]]--

-- Initialize auto-mod data
GM.AutoMod = GM.AutoMod or {
    offenses = {},
    rules = {},
    punishments = {}
}

-- Define a rule
function GM:DefineRule(ruleID, data)
    self.AutoMod.rules[ruleID] = {
        id = ruleID,
        name = data.name or ruleID,
        description = data.description or "",
        severity = data.severity or 1, -- 1-5
        maxViolations = data.maxViolations or 3,
        punishments = data.punishments or {}
    }
end

-- Register default rules
GM:DefineRule("spam", {
    name = "Spam",
    description = "Sending repeated messages",
    severity = 2,
    maxViolations = 3,
    punishments = {
        {count = 1, action = "warn"},
        {count = 2, action = "mute", duration = 300},
        {count = 3, action = "kick"}
    }
})

GM:DefineRule("rdm", {
    name = "Random Deathmatch",
    description = "Killing without roleplay reason",
    severity = 4,
    maxViolations = 2,
    punishments = {
        {count = 1, action = "warn"},
        {count = 2, action = "kick"}
    }
})

GM:DefineRule("combat_log", {
    name = "Combat Logging",
    description = "Disconnecting during combat",
    severity = 3,
    maxViolations = 2,
    punishments = {
        {count = 1, action = "warn"},
        {count = 2, action = "tempban", duration = 3600}
    }
})

GM:DefineRule("faction_abuse", {
    name = "Faction Abuse",
    description = "Abusing faction privileges",
    severity = 3,
    maxViolations = 2,
    punishments = {
        {count = 1, action = "warn"},
        {count = 2, action = "kick"}
    }
})

-- Get offense data path
local function GetOffenseDataPath()
    return "project_sovereign/offenses.txt"
end

-- Save offense data
function GM:SaveOffenses()
    if not SERVER then return false end
    
    local json = util.TableToJSON(self.AutoMod.offenses, true)
    if not json then
        self:ErrorLog("Failed to serialize offense data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write(GetOffenseDataPath(), json)
    
    self:DebugLog("Saved offense data")
    return true
end

-- Load offense data
function GM:LoadOffenses()
    if not SERVER then return false end
    
    local filePath = GetOffenseDataPath()
    
    if not file.Exists(filePath, "DATA") then
        self:Log("No offense data found, starting fresh")
        return false
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read offense data")
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse offense data")
        return false
    end
    
    self.AutoMod.offenses = data
    
    self:Log("Loaded offense data successfully")
    return true
end

-- Record a violation
function GM:RecordViolation(ply, ruleID, reason)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    local rule = self.AutoMod.rules[ruleID]
    if not rule then
        return false
    end
    
    local steamID = ply:SteamID()
    
    -- Initialize offense record
    if not self.AutoMod.offenses[steamID] then
        self.AutoMod.offenses[steamID] = {}
    end
    
    if not self.AutoMod.offenses[steamID][ruleID] then
        self.AutoMod.offenses[steamID][ruleID] = {
            count = 0,
            history = {}
        }
    end
    
    -- Add offense
    self.AutoMod.offenses[steamID][ruleID].count = self.AutoMod.offenses[steamID][ruleID].count + 1
    
    table.insert(self.AutoMod.offenses[steamID][ruleID].history, {
        timestamp = os.time(),
        reason = reason or "No reason provided"
    })
    
    local violationCount = self.AutoMod.offenses[steamID][ruleID].count
    
    self:SaveOffenses()
    
    -- Determine punishment
    local punishment = nil
    for _, p in ipairs(rule.punishments) do
        if violationCount >= p.count then
            punishment = p
        end
    end
    
    if punishment then
        self:ApplyPunishment(ply, punishment, rule, reason)
    end
    
    self:Log(string.format("%s violated rule '%s' (%d/%d violations): %s",
        ply:Nick(), rule.name, violationCount, rule.maxViolations, reason or ""))
    
    return true, violationCount
end

-- Apply punishment
function GM:ApplyPunishment(ply, punishment, rule, reason)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    local reasonText = reason or rule.description
    
    if punishment.action == "warn" then
        self:Notify(ply, string.format("WARNING: %s - %s", rule.name, reasonText), NOTIFY_ERROR)
        self:NotifyAll(string.format("%s received a warning for %s", ply:Nick(), rule.name), NOTIFY_GENERIC)
        
    elseif punishment.action == "mute" then
        -- Mute functionality would need to be implemented
        self:Notify(ply, string.format("You have been muted for %d seconds: %s",
            punishment.duration or 300, reasonText), NOTIFY_ERROR)
        
    elseif punishment.action == "kick" then
        self:NotifyAll(string.format("%s was kicked for %s", ply:Nick(), rule.name), NOTIFY_GENERIC)
        timer.Simple(1, function()
            if IsValid(ply) then
                ply:Kick(string.format("Rule Violation: %s", reasonText))
            end
        end)
        
    elseif punishment.action == "tempban" then
        self:NotifyAll(string.format("%s was temporarily banned for %s", ply:Nick(), rule.name), NOTIFY_GENERIC)
        -- Temporary ban would require ULX or similar admin mod
        self:Log(string.format("TEMPBAN: %s for %d seconds - %s", ply:Nick(), punishment.duration or 3600, reasonText))
    end
    
    hook.Run("ProjectSovereign_PunishmentApplied", ply, punishment, rule, reason)
    
    return true
end

-- Get player offenses
function GM:GetPlayerOffenses(ply)
    if not self:IsValidPlayer(ply) then return {} end
    
    local steamID = ply:SteamID()
    return self.AutoMod.offenses[steamID] or {}
end

-- Clear player offenses
function GM:ClearPlayerOffenses(ply, ruleID)
    if not SERVER then return false end
    
    if not self:IsValidPlayer(ply) then return false end
    
    local steamID = ply:SteamID()
    
    if ruleID then
        -- Clear specific rule violations
        if self.AutoMod.offenses[steamID] then
            self.AutoMod.offenses[steamID][ruleID] = nil
        end
    else
        -- Clear all violations
        self.AutoMod.offenses[steamID] = nil
    end
    
    self:SaveOffenses()
    return true
end

-- Commands

-- Warn player (admin)
GM:RegisterCommand("warn", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /warn <player> <rule> [reason]", NOTIFY_ERROR)
        GAMEMODE:Notify(ply, "Available rules: spam, rdm, combat_log, faction_abuse", NOTIFY_HINT)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local ruleID = args[2]
    if not GAMEMODE.AutoMod.rules[ruleID] then
        GAMEMODE:Notify(ply, "Invalid rule: " .. ruleID, NOTIFY_ERROR)
        return
    end
    
    local reason = ""
    if #args > 2 then
        for i = 3, #args do
            reason = reason .. args[i] .. " "
        end
        reason = string.Trim(reason)
    end
    
    local success, violationCount = GAMEMODE:RecordViolation(target, ruleID, reason)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Warned %s for %s (Violation #%d)",
            target:Nick(), ruleID, violationCount), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Failed to record violation", NOTIFY_ERROR)
    end
end, true, "Warn a player for rule violation (admin only)")

-- View player offenses (admin)
GM:RegisterCommand("offenses", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /offenses <player>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local offenses = GAMEMODE:GetPlayerOffenses(target)
    
    if table.Count(offenses) == 0 then
        GAMEMODE:Notify(ply, string.format("%s has no recorded offenses", target:Nick()), NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint(string.format("=== OFFENSES: %s ===", target:Nick()))
    
    for ruleID, data in pairs(offenses) do
        local rule = GAMEMODE.AutoMod.rules[ruleID]
        local ruleName = rule and rule.name or ruleID
        
        ply:ChatPrint(string.format("%s: %d violation%s", ruleName, data.count, data.count > 1 and "s" or ""))
        
        -- Show recent violations
        for i = math.max(1, #data.history - 2), #data.history do
            local violation = data.history[i]
            ply:ChatPrint(string.format("  - %s: %s",
                os.date("%Y-%m-%d %H:%M", violation.timestamp),
                violation.reason))
        end
    end
    
    ply:ChatPrint("===================")
end, true, "View player offenses (admin only)")

-- Clear offenses (admin)
GM:RegisterCommand("clearoffenses", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /clearoffenses <player> [rule]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local ruleID = args[2] or nil
    
    GAMEMODE:ClearPlayerOffenses(target, ruleID)
    
    if ruleID then
        GAMEMODE:Notify(ply, string.format("Cleared %s offenses for %s", ruleID, target:Nick()), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, string.format("Cleared all offenses for %s", target:Nick()), NOTIFY_GENERIC)
    end
    
    GAMEMODE:Log(string.format("%s cleared offenses for %s%s",
        ply:Nick(), target:Nick(), ruleID and (" (" .. ruleID .. ")") or ""))
end, true, "Clear player offenses (admin only)")

-- Load offenses on server init
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_LoadOffenses", function()
        GAMEMODE:LoadOffenses()
        GAMEMODE:Log(string.format("Auto-moderation initialized with %d rules", table.Count(GAMEMODE.AutoMod.rules)))
    end)
    
    -- Auto-save offenses periodically
    timer.Create("ProjectSovereign_OffenseAutoSave", 300, 0, function()
        GAMEMODE:SaveOffenses()
    end)
end
