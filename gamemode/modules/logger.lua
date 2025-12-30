--[[
    Logger Module
    Logs admin/player actions and events
]]--

-- Log queue
local logQueue = {}
local maxLogEntries = 1000

-- Log entry structure
local function CreateLogEntry(category, message, actor)
    return {
        timestamp = os.time(),
        timeString = os.date("%Y-%m-%d %H:%M:%S"),
        category = category,
        message = message,
        actor = actor and {
            name = actor:Nick(),
            steamID = actor:SteamID()
        } or nil
    }
end

-- Add log entry
local function AddLog(category, message, actor)
    if not GAMEMODE:GetConfig("EnableLogging") then
        return
    end
    
    local entry = CreateLogEntry(category, message, actor)
    table.insert(logQueue, entry)
    
    -- Maintain max queue size
    if #logQueue > maxLogEntries then
        table.remove(logQueue, 1)
    end
    
    -- Write to console
    if GAMEMODE:GetConfig("VerboseLogging") then
        GAMEMODE:Log(string.format("[%s] %s", category, message))
    end
end

-- Save logs to file
local function SaveLogs()
    if not SERVER then return end
    
    if #logQueue == 0 then
        return
    end
    
    local data = util.TableToJSON(logQueue, true)
    
    if not data then
        GAMEMODE:ErrorLog("Failed to serialize log data")
        return
    end
    
    file.CreateDir("project_sovereign")
    file.CreateDir("project_sovereign/logs")
    
    local filename = string.format("project_sovereign/logs/log_%s.txt", os.date("%Y-%m-%d"))
    
    -- Append to existing file or create new
    local existing = ""
    if file.Exists(filename, "DATA") then
        existing = file.Read(filename, "DATA") or ""
    end
    
    file.Write(filename, existing .. data .. "\n")
    
    GAMEMODE:DebugLog("Saved " .. #logQueue .. " log entries")
    
    -- Clear queue after saving
    logQueue = {}
end

-- Initialize logger
local function InitLogger()
    GAMEMODE:Log("Logger module initialized")
    
    if SERVER then
        -- Auto-save logs every 5 minutes
        timer.Create("ProjectSovereign_LogSave", 300, 0, SaveLogs)
        
        -- Save logs on shutdown
        hook.Add("ShutDown", "ProjectSovereign_SaveLogs", SaveLogs)
    end
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitLogger", InitLogger)
end

-- Public logging functions

function GM:LogAction(category, message, actor)
    AddLog(category, message, actor)
end

function GM:LogAdminAction(message, admin)
    if self:GetConfig("LogAdminActions") then
        AddLog("ADMIN", message, admin)
    end
end

function GM:LogPlayerAction(message, player)
    if self:GetConfig("LogPlayerActions") then
        AddLog("PLAYER", message, player)
    end
end

function GM:LogCombatAction(message, player)
    if self:GetConfig("LogCombat") then
        AddLog("COMBAT", message, player)
    end
end

function GM:LogEconomyAction(message, player)
    AddLog("ECONOMY", message, player)
end

function GM:LogFactionAction(message, player)
    AddLog("FACTION", message, player)
end

-- Hook into existing events
if SERVER then
    -- Log admin commands
    hook.Add("PlayerSay", "ProjectSovereign_LogCommands", function(ply, text)
        if string.sub(text, 1, 1) == "/" then
            local cmd = string.Explode(" ", text)[1]
            
            if GAMEMODE.Commands[string.lower(string.sub(cmd, 2))] then
                local commandData = GAMEMODE.Commands[string.lower(string.sub(cmd, 2))]
                
                if commandData.adminOnly then
                    GAMEMODE:LogAdminAction(string.format("Used command: %s", text), ply)
                else
                    GAMEMODE:LogPlayerAction(string.format("Used command: %s", text), ply)
                end
            end
        end
    end)
    
    -- Log player connections
    hook.Add("PlayerInitialSpawn", "ProjectSovereign_LogConnect", function(ply)
        GAMEMODE:LogPlayerAction(string.format("Connected to server"), ply)
    end)
    
    hook.Add("PlayerDisconnected", "ProjectSovereign_LogDisconnect", function(ply)
        GAMEMODE:LogPlayerAction(string.format("Disconnected from server"), ply)
    end)
    
    -- Log faction changes
    local oldSetPlayerFaction = GAMEMODE.SetPlayerFaction
    GAMEMODE.SetPlayerFaction = function(self, ply, faction, rank)
        local result, msg = oldSetPlayerFaction(self, ply, faction, rank)
        
        if result then
            self:LogFactionAction(string.format("Faction changed to %s (Rank: %s)", faction, rank or "default"), ply)
        end
        
        return result, msg
    end
    
    -- Log whitelist changes
    local oldAddToWhitelist = GAMEMODE.AddToWhitelist
    GAMEMODE.AddToWhitelist = function(self, ply, faction, rank)
        local result, msg = oldAddToWhitelist(self, ply, faction, rank)
        
        if result then
            self:LogAdminAction(string.format("Added whitelist: %s - %s (Rank: %s)", ply:Nick(), faction, rank), nil)
        end
        
        return result, msg
    end
    
    local oldRemoveFromWhitelist = GAMEMODE.RemoveFromWhitelist
    GAMEMODE.RemoveFromWhitelist = function(self, ply, faction)
        local result, msg = oldRemoveFromWhitelist(self, ply, faction)
        
        if result then
            self:LogAdminAction(string.format("Removed whitelist: %s - %s", ply:Nick(), faction), nil)
        end
        
        return result, msg
    end
    
    -- Log deaths
    hook.Add("PlayerDeath", "ProjectSovereign_LogDeaths", function(victim, inflictor, attacker)
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            GAMEMODE:LogCombatAction(string.format("Killed %s", victim:Nick()), attacker)
            GAMEMODE:LogCombatAction(string.format("Killed by %s", attacker:Nick()), victim)
        else
            GAMEMODE:LogCombatAction("Died", victim)
        end
    end)
end

-- View logs command (admin only)
GM:RegisterCommand("viewlogs", function(ply, args)
    local count = tonumber(args[1]) or 10
    count = math.Clamp(count, 1, 50)
    
    ply:ChatPrint(string.format("=== Last %d Log Entries ===", count))
    
    local startIndex = math.max(1, #logQueue - count + 1)
    
    for i = startIndex, #logQueue do
        local entry = logQueue[i]
        local actorName = entry.actor and entry.actor.name or "System"
        ply:ChatPrint(string.format("[%s] [%s] %s: %s", 
            entry.timeString, entry.category, actorName, entry.message))
    end
end, true, "View recent log entries")

-- Clear logs command (admin only)
GM:RegisterCommand("clearlogs", function(ply, args)
    logQueue = {}
    GAMEMODE:Notify(ply, "Log queue cleared", NOTIFY_GENERIC)
    GAMEMODE:LogAdminAction("Cleared log queue", ply)
end, true, "Clear the log queue")
