--[[
    Event Scheduler Module - Phase 2
    Time-based events system with recurring support
]]--

-- Initialize event data
GM.Events = GM.Events or {
    scheduled = {},
    active = {},
    completed = {},
    nextEventID = 1
}

-- Initialize events
local function InitEvents()
    GAMEMODE:Log("Event scheduler initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitEvents", InitEvents)
end

-- Get event data path
local function GetEventDataPath()
    return "project_sovereign/events.txt"
end

-- Save event data
function GM:SaveEvents()
    if not SERVER then return false end
    
    local data = {
        scheduled = self.Events.scheduled,
        active = self.Events.active,
        completed = self.Events.completed,
        nextEventID = self.Events.nextEventID
    }
    
    local json = util.TableToJSON(data, true)
    if not json then
        self:ErrorLog("Failed to serialize event data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write(GetEventDataPath(), json)
    
    self:DebugLog("Saved event data")
    return true
end

-- Load event data
function GM:LoadEvents()
    if not SERVER then return false end
    
    local filePath = GetEventDataPath()
    
    if not file.Exists(filePath, "DATA") then
        self:Log("No event data found, starting fresh")
        return false
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read event data")
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse event data")
        return false
    end
    
    self.Events.scheduled = data.scheduled or {}
    self.Events.active = data.active or {}
    self.Events.completed = data.completed or {}
    self.Events.nextEventID = data.nextEventID or 1
    
    self:Log("Loaded event data successfully")
    return true
end

-- Schedule an event
function GM:ScheduleEvent(eventType, startTime, duration, recurring, recurInterval, description)
    if not SERVER then return false end
    
    local eventID = self.Events.nextEventID
    self.Events.nextEventID = self.Events.nextEventID + 1
    
    local event = {
        id = eventID,
        type = eventType,
        description = description or "",
        startTime = startTime,
        duration = duration or 3600, -- Default 1 hour
        recurring = recurring or false,
        recurInterval = recurInterval or 86400, -- Default 24 hours
        createdAt = os.time(),
        active = false
    }
    
    self.Events.scheduled[eventID] = event
    self:SaveEvents()
    
    self:Log(string.format("Scheduled event #%d: %s at %s",
        eventID, eventType, os.date("%Y-%m-%d %H:%M:%S", startTime)))
    
    return true, eventID
end

-- Start an event
function GM:StartEvent(eventID)
    if not SERVER then return false end
    
    local event = self.Events.scheduled[eventID]
    if not event then
        return false, "Event not found"
    end
    
    event.active = true
    event.actualStartTime = os.time()
    event.endTime = os.time() + event.duration
    
    self.Events.active[eventID] = event
    self.Events.scheduled[eventID] = nil
    
    self:SaveEvents()
    
    -- Notify all players
    self:NotifyAll(string.format("EVENT STARTED: %s - %s", event.type, event.description), NOTIFY_GENERIC)
    
    self:Log(string.format("Event #%d started: %s", eventID, event.type))
    
    return true
end

-- End an event
function GM:EndEvent(eventID)
    if not SERVER then return false end
    
    local event = self.Events.active[eventID]
    if not event then
        return false, "Event not found"
    end
    
    event.active = false
    event.actualEndTime = os.time()
    
    -- Handle recurring events
    if event.recurring then
        -- Reschedule
        local newEventID = self.Events.nextEventID
        self.Events.nextEventID = self.Events.nextEventID + 1
        
        local newEvent = table.Copy(event)
        newEvent.id = newEventID
        newEvent.startTime = event.actualStartTime + event.recurInterval
        newEvent.active = false
        newEvent.actualStartTime = nil
        newEvent.endTime = nil
        newEvent.actualEndTime = nil
        
        self.Events.scheduled[newEventID] = newEvent
        
        self:Log(string.format("Recurring event #%d rescheduled as #%d", eventID, newEventID))
    end
    
    -- Move to completed
    self.Events.completed[eventID] = event
    self.Events.active[eventID] = nil
    
    self:SaveEvents()
    
    -- Notify all players
    self:NotifyAll(string.format("EVENT ENDED: %s", event.type), NOTIFY_GENERIC)
    
    self:Log(string.format("Event #%d ended: %s", eventID, event.type))
    
    return true
end

-- Cancel an event
function GM:CancelEvent(eventID)
    if not SERVER then return false end
    
    if self.Events.scheduled[eventID] then
        self.Events.scheduled[eventID] = nil
        self:SaveEvents()
        return true, "Scheduled event cancelled"
    elseif self.Events.active[eventID] then
        self:EndEvent(eventID)
        return true, "Active event ended"
    end
    
    return false, "Event not found"
end

-- Get upcoming events
function GM:GetUpcomingEvents(count)
    count = count or 10
    
    local upcoming = {}
    for id, event in pairs(self.Events.scheduled) do
        table.insert(upcoming, event)
    end
    
    -- Sort by start time
    table.sort(upcoming, function(a, b)
        return a.startTime < b.startTime
    end)
    
    -- Return only requested count
    local result = {}
    for i = 1, math.min(count, #upcoming) do
        result[i] = upcoming[i]
    end
    
    return result
end

-- Get active events
function GM:GetActiveEvents()
    return self.Events.active
end

-- Commands

-- List events command
GM:RegisterCommand("events", function(ply, args)
    local upcoming = GAMEMODE:GetUpcomingEvents(5)
    local active = GAMEMODE:GetActiveEvents()
    
    -- Show active events
    if table.Count(active) > 0 then
        ply:ChatPrint("=== ACTIVE EVENTS ===")
        for id, event in pairs(active) do
            local timeRemaining = event.endTime - os.time()
            ply:ChatPrint(string.format("#%d | %s - %s",
                id, event.type, event.description))
            ply:ChatPrint(string.format("  Time Remaining: %s",
                GAMEMODE:FormatTime(math.max(0, timeRemaining))))
        end
        ply:ChatPrint("====================")
    end
    
    -- Show upcoming events
    if #upcoming > 0 then
        ply:ChatPrint("=== UPCOMING EVENTS ===")
        for _, event in ipairs(upcoming) do
            local timeUntil = event.startTime - os.time()
            ply:ChatPrint(string.format("#%d | %s - %s",
                event.id, event.type, event.description))
            ply:ChatPrint(string.format("  Starts in: %s%s",
                GAMEMODE:FormatTime(math.max(0, timeUntil)),
                event.recurring and " (Recurring)" or ""))
        end
        ply:ChatPrint("======================")
    end
    
    if table.Count(active) == 0 and #upcoming == 0 then
        GAMEMODE:Notify(ply, "No events scheduled", NOTIFY_HINT)
    end
end, false, "View active and upcoming events")

-- Schedule event command (admin)
GM:RegisterCommand("scheduleevent", function(ply, args)
    if #args < 3 then
        GAMEMODE:Notify(ply, "Usage: /scheduleevent <type> <minutes_from_now> <duration_minutes> [description]", NOTIFY_ERROR)
        GAMEMODE:Notify(ply, "Example: /scheduleevent CombatTournament 30 60 Monthly tournament", NOTIFY_HINT)
        return
    end
    
    local eventType = args[1]
    local minutesFromNow = tonumber(args[2])
    local durationMinutes = tonumber(args[3])
    
    if not minutesFromNow or minutesFromNow < 0 then
        GAMEMODE:Notify(ply, "Invalid start time", NOTIFY_ERROR)
        return
    end
    
    if not durationMinutes or durationMinutes <= 0 then
        GAMEMODE:Notify(ply, "Invalid duration", NOTIFY_ERROR)
        return
    end
    
    local description = ""
    if #args > 3 then
        for i = 4, #args do
            description = description .. args[i] .. " "
        end
        description = string.Trim(description)
    end
    
    local startTime = os.time() + (minutesFromNow * 60)
    local duration = durationMinutes * 60
    
    local success, eventID = GAMEMODE:ScheduleEvent(eventType, startTime, duration, false, 0, description)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Scheduled event #%d: %s", eventID, eventType), NOTIFY_GENERIC)
        GAMEMODE:NotifyAll(string.format("New event scheduled: %s in %d minutes", eventType, minutesFromNow), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s scheduled event #%d: %s", ply:Nick(), eventID, eventType))
    else
        GAMEMODE:Notify(ply, "Failed to schedule event", NOTIFY_ERROR)
    end
end, true, "Schedule an event (admin only)")

-- Schedule recurring event command (admin)
GM:RegisterCommand("schedulerecurring", function(ply, args)
    if #args < 4 then
        GAMEMODE:Notify(ply, "Usage: /schedulerecurring <type> <minutes_from_now> <duration_minutes> <interval_hours> [description]", NOTIFY_ERROR)
        return
    end
    
    local eventType = args[1]
    local minutesFromNow = tonumber(args[2])
    local durationMinutes = tonumber(args[3])
    local intervalHours = tonumber(args[4])
    
    if not minutesFromNow or minutesFromNow < 0 then
        GAMEMODE:Notify(ply, "Invalid start time", NOTIFY_ERROR)
        return
    end
    
    if not durationMinutes or durationMinutes <= 0 then
        GAMEMODE:Notify(ply, "Invalid duration", NOTIFY_ERROR)
        return
    end
    
    if not intervalHours or intervalHours <= 0 then
        GAMEMODE:Notify(ply, "Invalid interval", NOTIFY_ERROR)
        return
    end
    
    local description = ""
    if #args > 4 then
        for i = 5, #args do
            description = description .. args[i] .. " "
        end
        description = string.Trim(description)
    end
    
    local startTime = os.time() + (minutesFromNow * 60)
    local duration = durationMinutes * 60
    local interval = intervalHours * 3600
    
    local success, eventID = GAMEMODE:ScheduleEvent(eventType, startTime, duration, true, interval, description)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Scheduled recurring event #%d: %s", eventID, eventType), NOTIFY_GENERIC)
        GAMEMODE:NotifyAll(string.format("New recurring event: %s (every %d hours)", eventType, intervalHours), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s scheduled recurring event #%d: %s", ply:Nick(), eventID, eventType))
    else
        GAMEMODE:Notify(ply, "Failed to schedule event", NOTIFY_ERROR)
    end
end, true, "Schedule a recurring event (admin only)")

-- Cancel event command (admin)
GM:RegisterCommand("cancelevent", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /cancelevent <eventID>", NOTIFY_ERROR)
        return
    end
    
    local eventID = tonumber(args[1])
    if not eventID then
        GAMEMODE:Notify(ply, "Invalid event ID", NOTIFY_ERROR)
        return
    end
    
    local success, msg = GAMEMODE:CancelEvent(eventID)
    
    if success then
        GAMEMODE:Notify(ply, "Event cancelled: " .. msg, NOTIFY_GENERIC)
        GAMEMODE:Log(string.format("%s cancelled event #%d", ply:Nick(), eventID))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Cancel an event (admin only)")

-- Start event command (admin)
GM:RegisterCommand("startevent", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /startevent <eventID>", NOTIFY_ERROR)
        return
    end
    
    local eventID = tonumber(args[1])
    if not eventID then
        GAMEMODE:Notify(ply, "Invalid event ID", NOTIFY_ERROR)
        return
    end
    
    local success, msg = GAMEMODE:StartEvent(eventID)
    
    if success then
        GAMEMODE:Notify(ply, "Event started successfully", NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Start an event manually (admin only)")

-- End event command (admin)
GM:RegisterCommand("endevent", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /endevent <eventID>", NOTIFY_ERROR)
        return
    end
    
    local eventID = tonumber(args[1])
    if not eventID then
        GAMEMODE:Notify(ply, "Invalid event ID", NOTIFY_ERROR)
        return
    end
    
    local success, msg = GAMEMODE:EndEvent(eventID)
    
    if success then
        GAMEMODE:Notify(ply, "Event ended successfully", NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "End an event manually (admin only)")

-- Load events on server init
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_LoadEvents", function()
        GAMEMODE:LoadEvents()
    end)
    
    -- Auto-save events periodically
    timer.Create("ProjectSovereign_EventAutoSave", 300, 0, function()
        GAMEMODE:SaveEvents()
    end)
    
    -- Check for events to start/end
    timer.Create("ProjectSovereign_EventScheduler", 60, 0, function()
        local currentTime = os.time()
        
        -- Check scheduled events
        for eventID, event in pairs(GAMEMODE.Events.scheduled) do
            if currentTime >= event.startTime then
                GAMEMODE:StartEvent(eventID)
            end
        end
        
        -- Check active events
        for eventID, event in pairs(GAMEMODE.Events.active) do
            if event.endTime and currentTime >= event.endTime then
                GAMEMODE:EndEvent(eventID)
            end
        end
    end)
end
