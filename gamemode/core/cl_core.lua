--[[
    Client Core
    Client-side core functionality and UI management
]]--

-- Client-side data
GM.ClientData = GM.ClientData or {}

-- Initialize client-side systems
local function InitializeClient()
    GAMEMODE:Log("Client-side core initialized")
    
    -- Request initial data from server
    timer.Simple(1, function()
        if IsValid(LocalPlayer()) then
            GAMEMODE:DebugLog("Client ready, requesting server data")
        end
    end)
end

hook.Add("Initialize", "ProjectSovereign_ClientInit", InitializeClient)

-- Receive notification from server
net.Receive = net.Receive or function() end

-- Client-side notification display
function GM:ClientNotify(message, notifyType, duration)
    notifyType = notifyType or NOTIFY_GENERIC
    duration = duration or 5
    
    -- Use GMod's built-in notification system
    notification.AddLegacy(message, notifyType, duration)
    
    -- Also print to chat for visibility
    chat.AddText(Color(200, 200, 200), "[PROJECT SOVEREIGN] ", Color(255, 255, 255), message)
end

-- Display faction information in HUD context
function GM:GetFactionHUDInfo()
    local ply = LocalPlayer()
    
    if not IsValid(ply) then
        return nil
    end
    
    return {
        faction = ply.Faction or "Unknown",
        rank = ply.Rank or "Unknown",
        credits = ply.Credits or 0
    }
end

-- Client-side faction color for player
function GM:GetClientFactionColor(ply)
    if not IsValid(ply) then
        return Color(255, 255, 255)
    end
    
    local faction = ply.Faction or self:GetConfig("DefaultFaction")
    
    return self:GetFactionColor(faction)
end

-- Show faction menu (placeholder for future implementation)
function GM:ShowFactionMenu()
    self:ClientNotify("Faction menu not yet implemented", NOTIFY_HINT)
end

-- Show help menu
function GM:ShowHelpMenu()
    local helpText = [[
=== PROJECT SOVEREIGN - HELP ===

COMMANDS:
Type /help in chat to see all available commands

FACTIONS:
Contact an admin to get whitelisted for a faction

CONTROLS:
F1 - Help Menu
F2 - Faction Menu (Coming Soon)

For more information, contact server administrators.
]]
    
    chat.AddText(Color(100, 200, 255), helpText)
end

-- Bind help menu to F1
hook.Add("PlayerBindPress", "ProjectSovereign_Binds", function(ply, bind, pressed)
    if bind == "gm_showhelp" and pressed then
        GAMEMODE:ShowHelpMenu()
        return true
    end
    
    if bind == "gm_showteam" and pressed then
        GAMEMODE:ShowFactionMenu()
        return true
    end
end)

print("Client core (cl_core.lua) loaded")
