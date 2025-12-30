--[[
    Analytics System Module - Phase 2
    Track player activity, wealth distribution, and faction power
]]--

-- Initialize analytics data
GM.Analytics = GM.Analytics or {
    lastUpdate = 0,
    updateInterval = 300, -- Update every 5 minutes
    data = {}
end

-- Update analytics
function GM:UpdateAnalytics()
    if not SERVER then return end
    
    local currentTime = os.time()
    
    -- Only update if enough time has passed
    if currentTime - self.Analytics.lastUpdate < self.Analytics.updateInterval then
        return
    end
    
    self.Analytics.lastUpdate = currentTime
    
    local data = {
        timestamp = currentTime,
        playerCount = #player.GetAll(),
        totalWealth = 0,
        factionPower = {},
        factionPlayerCount = {},
        averagePlaytime = 0,
        topPlayers = {}
    }
    
    local totalPlaytime = 0
    local playerWealthData = {}
    
    -- Gather player data
    for _, ply in ipairs(player.GetAll()) do
        if self:IsValidPlayer(ply) then
            -- Track wealth
            local credits = self:GetPlayerCredits(ply)
            data.totalWealth = data.totalWealth + credits
            
            table.insert(playerWealthData, {
                name = ply:Nick(),
                steamID = ply:SteamID(),
                credits = credits
            })
            
            -- Track faction distribution
            local faction = self:GetPlayerFaction(ply)
            if faction then
                data.factionPlayerCount[faction] = (data.factionPlayerCount[faction] or 0) + 1
                data.factionPower[faction] = (data.factionPower[faction] or 0) + credits
            end
            
            -- Track playtime
            if ply.PlayerData and ply.PlayerData.playtime then
                totalPlaytime = totalPlaytime + ply.PlayerData.playtime
            end
        end
    end
    
    -- Calculate average playtime
    if data.playerCount > 0 then
        data.averagePlaytime = totalPlaytime / data.playerCount
    end
    
    -- Sort players by wealth (top 10)
    table.sort(playerWealthData, function(a, b)
        return a.credits > b.credits
    end)
    
    for i = 1, math.min(10, #playerWealthData) do
        table.insert(data.topPlayers, playerWealthData[i])
    end
    
    self.Analytics.data = data
end

-- Get analytics data
function GM:GetAnalytics()
    self:UpdateAnalytics()
    return self.Analytics.data
end

-- Commands

-- View analytics dashboard (admin)
GM:RegisterCommand("analytics", function(ply, args)
    local data = GAMEMODE:GetAnalytics()
    
    ply:ChatPrint("=== SERVER ANALYTICS ===")
    ply:ChatPrint(string.format("Last Updated: %s", os.date("%Y-%m-%d %H:%M:%S", data.timestamp)))
    ply:ChatPrint("")
    
    ply:ChatPrint("=== PLAYER STATISTICS ===")
    ply:ChatPrint(string.format("Online Players: %d", data.playerCount))
    ply:ChatPrint(string.format("Average Playtime: %s", GAMEMODE:FormatTime(data.averagePlaytime)))
    ply:ChatPrint("")
    
    ply:ChatPrint("=== ECONOMY ===")
    ply:ChatPrint(string.format("Total Wealth: %s", GAMEMODE:FormatCredits(data.totalWealth)))
    if data.playerCount > 0 then
        ply:ChatPrint(string.format("Average Wealth: %s",
            GAMEMODE:FormatCredits(math.floor(data.totalWealth / data.playerCount))))
    end
    ply:ChatPrint("")
    
    ply:ChatPrint("=== TOP 10 RICHEST PLAYERS ===")
    for i, pdata in ipairs(data.topPlayers) do
        ply:ChatPrint(string.format("%d. %s - %s", i, pdata.name, GAMEMODE:FormatCredits(pdata.credits)))
    end
    ply:ChatPrint("")
    
    ply:ChatPrint("=== FACTION DISTRIBUTION ===")
    for faction, count in pairs(data.factionPlayerCount) do
        local power = data.factionPower[faction] or 0
        ply:ChatPrint(string.format("%s: %d players | Power: %s",
            faction, count, GAMEMODE:FormatCredits(power)))
    end
    
    ply:ChatPrint("========================")
end, true, "View server analytics (admin only)")

-- View faction power
GM:RegisterCommand("factionpower", function(ply, args)
    local data = GAMEMODE:GetAnalytics()
    
    ply:ChatPrint("=== FACTION POWER ===")
    
    if table.Count(data.factionPower) == 0 then
        ply:ChatPrint("No faction power data available")
    else
        -- Sort factions by power
        local factionList = {}
        for faction, power in pairs(data.factionPower) do
            table.insert(factionList, {faction = faction, power = power})
        end
        
        table.sort(factionList, function(a, b)
            return a.power > b.power
        end)
        
        for i, data in ipairs(factionList) do
            local playerCount = GAMEMODE:GetAnalytics().factionPlayerCount[data.faction] or 0
            ply:ChatPrint(string.format("%d. %s - %s (%d players)",
                i, data.faction, GAMEMODE:FormatCredits(data.power), playerCount))
        end
    end
    
    ply:ChatPrint("====================")
end, false, "View faction power rankings")

-- View wealth distribution
GM:RegisterCommand("wealthdistribution", function(ply, args)
    local data = GAMEMODE:GetAnalytics()
    
    ply:ChatPrint("=== WEALTH DISTRIBUTION ===")
    ply:ChatPrint(string.format("Total Server Wealth: %s", GAMEMODE:FormatCredits(data.totalWealth)))
    
    if data.playerCount > 0 then
        ply:ChatPrint(string.format("Average per Player: %s",
            GAMEMODE:FormatCredits(math.floor(data.totalWealth / data.playerCount))))
    end
    
    ply:ChatPrint("")
    ply:ChatPrint("Top Wealth Holders:")
    
    for i, pdata in ipairs(data.topPlayers) do
        local percentage = data.totalWealth > 0 and (pdata.credits / data.totalWealth * 100) or 0
        ply:ChatPrint(string.format("%d. %s - %s (%.1f%%)",
            i, pdata.name, GAMEMODE:FormatCredits(pdata.credits), percentage))
    end
    
    ply:ChatPrint("===========================")
end, true, "View wealth distribution (admin only)")

-- Auto-update analytics periodically
if SERVER then
    timer.Create("ProjectSovereign_AnalyticsUpdate", 300, 0, function()
        GAMEMODE:UpdateAnalytics()
    end)
    
    hook.Add("Initialize", "ProjectSovereign_AnalyticsInit", function()
        GAMEMODE:Log("Analytics system initialized")
        GAMEMODE:UpdateAnalytics()
    end)
end
