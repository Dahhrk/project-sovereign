--[[
    Commands System
    Handles admin and player commands
]]--

-- Command registry
GM.Commands = GM.Commands or {}

-- Register a command
function GM:RegisterCommand(name, callback, adminOnly, description)
    self.Commands[string.lower(name)] = {
        callback = callback,
        adminOnly = adminOnly or false,
        description = description or "No description provided"
    }
end

    -- Process chat command
local function ProcessCommand(ply, text)
    if string.sub(text, 1, 1) ~= "/" then
        return
    end
    
    local args = string.Explode(" ", text)
    local cmd = string.lower(string.sub(args[1], 2)) -- Remove the /
    table.remove(args, 1)
    
    local command = GAMEMODE.Commands[cmd]
    
    if not command then
        return
    end
    
    -- Check admin permission
    if command.adminOnly and not GAMEMODE:HasPermission(ply, "admin") then
        GAMEMODE:Notify(ply, "You do not have permission to use this command.", NOTIFY_ERROR)
        return ""
    end
    
    -- Execute command
    local success, err = pcall(command.callback, ply, args)
    
    if not success then
        GAMEMODE:ErrorLog("Command error: " .. tostring(err))
        GAMEMODE:Notify(ply, "An error occurred while executing the command.", NOTIFY_ERROR)
    end
    
    return ""
end

if SERVER then
    hook.Add("PlayerSay", "ProjectSovereign_Commands", ProcessCommand)
end

-- Register built-in commands

-- Add whitelist command
GM:RegisterCommand("addwhitelist", function(ply, args)
    if #args < 3 then
        GAMEMODE:Notify(ply, "Usage: /addwhitelist <player> <faction> <rank>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = args[2]
    local rank = args[3]
    
    local success, msg = GAMEMODE:AddToWhitelist(target, faction, rank)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Added %s to %s whitelist as %s", target:Nick(), faction, rank), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("You have been whitelisted for %s as %s", faction, rank), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s added %s to %s whitelist as %s", ply:Nick(), target:Nick(), faction, rank))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Add a player to a faction whitelist")

-- Remove whitelist command
GM:RegisterCommand("removewhitelist", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /removewhitelist <player> <faction>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = args[2]
    
    local success, msg = GAMEMODE:RemoveFromWhitelist(target, faction)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Removed %s from %s whitelist", target:Nick(), faction), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("You have been removed from %s whitelist", faction), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s removed %s from %s whitelist", ply:Nick(), target:Nick(), faction))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Remove a player from a faction whitelist")

-- Set faction command
GM:RegisterCommand("setfaction", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /setfaction <player> <faction> [rank]", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = args[2]
    local rank = args[3] or nil
    
    local success, msg = GAMEMODE:SetPlayerFaction(target, faction, rank)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Set %s's faction to %s", target:Nick(), faction), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("Your faction has been set to %s", faction), NOTIFY_HINT)
        GAMEMODE:Log(string.format("%s set %s's faction to %s", ply:Nick(), target:Nick(), faction))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Set a player's faction")

-- Force rank command
GM:RegisterCommand("forcerank", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /forcerank <player> <rank>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local rank = args[2]
    local faction = GAMEMODE:GetPlayerFaction(target)
    
    if not faction then
        GAMEMODE:Notify(ply, "Target player has no faction", NOTIFY_ERROR)
        return
    end
    
    if not GAMEMODE:IsValidRank(faction, rank) then
        GAMEMODE:Notify(ply, string.format("Invalid rank '%s' for faction %s", rank, faction), NOTIFY_ERROR)
        return
    end
    
    target.Rank = rank
    GAMEMODE:ApplyLoadout(target)
    
    GAMEMODE:Notify(ply, string.format("Set %s's rank to %s", target:Nick(), rank), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Your rank has been set to %s", rank), NOTIFY_HINT)
    GAMEMODE:Log(string.format("%s set %s's rank to %s", ply:Nick(), target:Nick(), rank))
end, true, "Force set a player's rank")

-- Transfer credits command
GM:RegisterCommand("transfercredits", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /transfercredits <player> <amount>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[2])
    if not amount or amount <= 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    if not GAMEMODE:CanAfford(ply, amount) then
        GAMEMODE:Notify(ply, "You don't have enough credits", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:RemovePlayerCredits(ply, amount)
    GAMEMODE:AddPlayerCredits(target, amount)
    
    GAMEMODE:Notify(ply, string.format("Transferred %s to %s", GAMEMODE:FormatCredits(amount), target:Nick()), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Received %s from %s", GAMEMODE:FormatCredits(amount), ply:Nick()), NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s transferred %d credits to %s", ply:Nick(), amount, target:Nick()))
end, false, "Transfer credits to another player")

-- Give credits command (admin only)
GM:RegisterCommand("givecredits", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /givecredits <player> <amount>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local amount = tonumber(args[2])
    if not amount or amount <= 0 then
        GAMEMODE:Notify(ply, "Invalid amount", NOTIFY_ERROR)
        return
    end
    
    GAMEMODE:AddPlayerCredits(target, amount)
    
    GAMEMODE:Notify(ply, string.format("Gave %s to %s", GAMEMODE:FormatCredits(amount), target:Nick()), NOTIFY_GENERIC)
    GAMEMODE:Notify(target, string.format("Received %s", GAMEMODE:FormatCredits(amount)), NOTIFY_GENERIC)
    GAMEMODE:Log(string.format("%s gave %d credits to %s", ply:Nick(), amount, target:Nick()))
end, true, "Give credits to a player")

-- Debug player command
GM:RegisterCommand("debugplayer", function(ply, args)
    local target = ply
    
    if #args >= 1 then
        target = GAMEMODE:FindPlayer(args[1])
        if not target then
            GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
            return
        end
    end
    
    local info = {
        "=== Player Debug Info ===",
        "Name: " .. target:Nick(),
        "SteamID: " .. target:SteamID(),
        "Faction: " .. (GAMEMODE:GetPlayerFaction(target) or "None"),
        "Rank: " .. (GAMEMODE:GetPlayerRank(target) or "None"),
        "Credits: " .. GAMEMODE:FormatCredits(GAMEMODE:GetPlayerCredits(target)),
        "Health: " .. target:Health(),
        "Armor: " .. target:Armor()
    }
    
    for _, line in ipairs(info) do
        ply:ChatPrint(line)
    end
end, true, "Display debug information about a player")

-- Help command
GM:RegisterCommand("help", function(ply, args)
    ply:ChatPrint("=== Available Commands ===")
    
    for name, cmd in pairs(GAMEMODE.Commands) do
        if not cmd.adminOnly or GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint(string.format("/%s - %s", name, cmd.description))
        end
    end
end, false, "Display available commands")

-- Promote player command (admin)
GM:RegisterCommand("promote", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /promote <player>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = GAMEMODE:GetPlayerFaction(target)
    if not faction then
        GAMEMODE:Notify(ply, "Player is not in a faction", NOTIFY_ERROR)
        return
    end
    
    local currentRank = GAMEMODE:GetPlayerRank(target)
    if not currentRank then
        GAMEMODE:Notify(ply, "Player has no rank", NOTIFY_ERROR)
        return
    end
    
    -- Get ranks for faction
    local factionData = GAMEMODE.Factions and GAMEMODE.Factions[faction]
    if not factionData or not factionData.ranks then
        GAMEMODE:Notify(ply, "Invalid faction data", NOTIFY_ERROR)
        return
    end
    
    -- Find current rank index
    local currentIndex = 0
    for i, rank in ipairs(factionData.ranks) do
        if rank == currentRank then
            currentIndex = i
            break
        end
    end
    
    if currentIndex == 0 then
        GAMEMODE:Notify(ply, "Could not find current rank in faction", NOTIFY_ERROR)
        return
    end
    
    -- Check if already at max rank
    if currentIndex >= #factionData.ranks then
        GAMEMODE:Notify(ply, string.format("%s is already at max rank (%s)", target:Nick(), currentRank), NOTIFY_ERROR)
        return
    end
    
    -- Promote to next rank
    local newRank = factionData.ranks[currentIndex + 1]
    
    local success, msg = GAMEMODE:SetPlayerFaction(target, faction, newRank)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Promoted %s from %s to %s", target:Nick(), currentRank, newRank), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("You have been promoted to %s!", newRank), NOTIFY_HINT)
        GAMEMODE:NotifyAll(string.format("%s has been promoted to %s", target:Nick(), newRank), NOTIFY_GENERIC)
        GAMEMODE:Log(string.format("%s promoted %s from %s to %s", ply:Nick(), target:Nick(), currentRank, newRank))
        
        -- Award skill points for promotion
        GAMEMODE:AwardSkillPoints(target, 1)
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Promote a player to the next rank")

-- Demote player command (admin)
GM:RegisterCommand("demote", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /demote <player>", NOTIFY_ERROR)
        return
    end
    
    local target = GAMEMODE:FindPlayer(args[1])
    if not target then
        GAMEMODE:Notify(ply, "Player not found: " .. args[1], NOTIFY_ERROR)
        return
    end
    
    local faction = GAMEMODE:GetPlayerFaction(target)
    if not faction then
        GAMEMODE:Notify(ply, "Player is not in a faction", NOTIFY_ERROR)
        return
    end
    
    local currentRank = GAMEMODE:GetPlayerRank(target)
    if not currentRank then
        GAMEMODE:Notify(ply, "Player has no rank", NOTIFY_ERROR)
        return
    end
    
    -- Get ranks for faction
    local factionData = GAMEMODE.Factions and GAMEMODE.Factions[faction]
    if not factionData or not factionData.ranks then
        GAMEMODE:Notify(ply, "Invalid faction data", NOTIFY_ERROR)
        return
    end
    
    -- Find current rank index
    local currentIndex = 0
    for i, rank in ipairs(factionData.ranks) do
        if rank == currentRank then
            currentIndex = i
            break
        end
    end
    
    if currentIndex == 0 then
        GAMEMODE:Notify(ply, "Could not find current rank in faction", NOTIFY_ERROR)
        return
    end
    
    -- Check if already at lowest rank
    if currentIndex <= 1 then
        GAMEMODE:Notify(ply, string.format("%s is already at lowest rank (%s)", target:Nick(), currentRank), NOTIFY_ERROR)
        return
    end
    
    -- Demote to previous rank
    local newRank = factionData.ranks[currentIndex - 1]
    
    local success, msg = GAMEMODE:SetPlayerFaction(target, faction, newRank)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Demoted %s from %s to %s", target:Nick(), currentRank, newRank), NOTIFY_GENERIC)
        GAMEMODE:Notify(target, string.format("You have been demoted to %s", newRank), NOTIFY_ERROR)
        GAMEMODE:Log(string.format("%s demoted %s from %s to %s", ply:Nick(), target:Nick(), currentRank, newRank))
    else
        GAMEMODE:Notify(ply, "Error: " .. msg, NOTIFY_ERROR)
    end
end, true, "Demote a player to the previous rank")

