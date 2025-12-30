--[[
    Utility Functions
    Helper functions used throughout the gamemode
]]--

-- Print a message to server console with gamemode prefix
function GM:Log(message, level)
    level = level or "INFO"
    local prefix = "[PROJECT SOVEREIGN]"
    local timestamp = os.date("%H:%M:%S")
    
    print(string.format("%s [%s] [%s] %s", prefix, timestamp, level, message))
end

-- Print a debug message (only if debug is enabled)
function GM:DebugLog(message)
    if self:GetConfig("EnableDebug") then
        self:Log(message, "DEBUG")
    end
end

-- Print an error message
function GM:ErrorLog(message)
    self:Log(message, "ERROR")
    ErrorNoHalt(message .. "\n")
end

-- Sanitize player input to prevent exploits
function GM:SanitizeString(str)
    if not str then return "" end
    
    -- Remove potentially dangerous characters
    str = string.gsub(str, "[<>\"']", "")
    -- Trim whitespace
    str = string.Trim(str)
    
    return str
end

-- Check if a player is valid and connected
function GM:IsValidPlayer(ply)
    return IsValid(ply) and ply:IsPlayer() and not ply:IsBot()
end

-- Get a player by partial name or SteamID
function GM:FindPlayer(identifier)
    if not identifier or identifier == "" then
        return nil
    end
    
    identifier = string.lower(identifier)
    
    -- First try exact match
    for _, ply in ipairs(player.GetAll()) do
        if string.lower(ply:Nick()) == identifier then
            return ply
        end
        
        if ply:SteamID() == identifier or ply:SteamID64() == identifier then
            return ply
        end
    end
    
    -- Try partial match
    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), identifier, 1, true) then
            return ply
        end
    end
    
    return nil
end

-- Format credits with thousand separators
function GM:FormatCredits(amount)
    if not amount then return "0" end
    
    local formatted = tostring(math.floor(amount))
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return formatted .. " Credits"
end

-- Format time in seconds to human-readable format
function GM:FormatTime(seconds)
    if not seconds then return "0s" end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, minutes, secs)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

-- Check if a player has permission (admin, superadmin, etc.)
function GM:HasPermission(ply, permission)
    if not self:IsValidPlayer(ply) then
        return false
    end
    
    permission = string.lower(permission or "")
    
    if permission == "superadmin" then
        return ply:IsSuperAdmin()
    elseif permission == "admin" then
        return ply:IsAdmin() or ply:IsSuperAdmin()
    elseif permission == "moderator" then
        -- You can extend this with custom user groups
        return ply:IsAdmin() or ply:IsSuperAdmin()
    end
    
    return false
end

-- Send a notification to a player
function GM:Notify(ply, message, notifyType, duration)
    if not self:IsValidPlayer(ply) then return end
    
    notifyType = notifyType or NOTIFY_GENERIC
    duration = duration or 5
    
    if SERVER then
        ply:ChatPrint(message)
        -- You can also use a custom notification system here
    end
end

-- Send a notification to all players
function GM:NotifyAll(message, notifyType, duration)
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            self:Notify(ply, message, notifyType, duration)
        end
    end
end

-- Table deep copy
function GM:TableCopy(tbl)
    if type(tbl) ~= "table" then return tbl end
    
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:TableCopy(v)
        else
            copy[k] = v
        end
    end
    
    return copy
end

-- Check if a table contains a value
function GM:TableHasValue(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Generate a unique ID
function GM:GenerateUID()
    return string.format("%s_%s", os.time(), math.random(1000, 9999))
end

-- Clamp a value between min and max
function GM:Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end
