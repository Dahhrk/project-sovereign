--[[
    Project Sovereign - Phase 8
    Seasonal Content and Live Updates
    
    Rotating seasonal challenges with exclusive rewards.
]]--

if SERVER then
    GAMEMODE.Seasons = GAMEMODE.Seasons or {}
    GAMEMODE.SeasonData = GAMEMODE.SeasonData or {
        currentSeason = nil,
        seasonHistory = {},
        playerProgress = {},
        challenges = {},
        rewards = {}
    }
    
    -- Season definitions
    local SEASON_TEMPLATES = {
        {
            id = "war_season",
            name = "Season of War",
            description = "Prove your combat prowess",
            duration = 2592000, -- 30 days
            challenges = {
                {id = "win_battles", name = "Victory Streak", requirement = 50, type = "kills"},
                {id = "capture_territories", name = "Conqueror", requirement = 5, type = "territories"},
                {id = "faction_dominance", name = "Faction Dominance", requirement = 1000, type = "faction_points"}
            },
            rewards = {
                {tier = 1, credits = 10000, items = {"war_trophy"}},
                {tier = 2, credits = 25000, items = {"war_trophy", "elite_emblem"}},
                {tier = 3, credits = 50000, items = {"war_trophy", "elite_emblem", "legendary_banner"}}
            }
        },
        {
            id = "trade_season",
            name = "Season of Prosperity",
            description = "Dominate the economy",
            duration = 2592000,
            challenges = {
                {id = "trade_volume", name = "Trade Master", requirement = 100000, type = "credits_traded"},
                {id = "business_empire", name = "Business Tycoon", requirement = 3, type = "businesses"},
                {id = "wealth_accumulation", name = "Wealthy Elite", requirement = 500000, type = "total_wealth"}
            },
            rewards = {
                {tier = 1, credits = 15000, items = {"trade_license"}},
                {tier = 2, credits = 35000, items = {"trade_license", "merchant_emblem"}},
                {tier = 3, credits = 75000, items = {"trade_license", "merchant_emblem", "golden_badge"}}
            }
        },
        {
            id = "exploration_season",
            name = "Season of Discovery",
            description = "Explore the galaxy",
            duration = 2592000,
            challenges = {
                {id = "visit_sectors", name = "Galaxy Explorer", requirement = 20, type = "sectors_visited"},
                {id = "discover_planets", name = "Planet Discoverer", requirement = 15, type = "planets_discovered"},
                {id = "anomaly_hunter", name = "Anomaly Hunter", requirement = 10, type = "anomalies_found"}
            },
            rewards = {
                {tier = 1, credits = 12000, items = {"explorer_badge"}},
                {tier = 2, credits = 30000, items = {"explorer_badge", "star_map"}},
                {tier = 3, credits = 60000, items = {"explorer_badge", "star_map", "cosmic_compass"}}
            }
        }
    }
    
    -- Configuration
    local CONFIG = {
        SeasonDuration = 2592000, -- 30 days default
        ResetReputationOnNewSeason = false,
        MinimumParticipants = 5,
        UpdateInterval = 3600 -- Update every hour
    }
    
    -- Initialize seasonal system
    function GAMEMODE:InitializeSeasons()
        self:LoadSeasonData()
        
        -- Start first season if none active
        if not self.SeasonData.currentSeason then
            self:StartNewSeason()
        end
        
        -- Check season status periodically
        timer.Create("SeasonUpdate", CONFIG.UpdateInterval, 0, function()
            self:UpdateSeasonStatus()
        end)
        
        print("[Seasons] Seasonal content system initialized")
    end
    
    -- Start new season
    function GAMEMODE:StartNewSeason()
        -- Select random season template
        local template = SEASON_TEMPLATES[math.random(1, #SEASON_TEMPLATES)]
        
        local seasonId = "season_" .. os.time()
        
        self.SeasonData.currentSeason = {
            id = seasonId,
            name = template.name,
            description = template.description,
            startTime = os.time(),
            endTime = os.time() + template.duration,
            challenges = template.challenges,
            rewards = template.rewards,
            participants = {},
            leaderboard = {}
        }
        
        -- Reset player progress for new season
        self.SeasonData.playerProgress = {}
        
        self:SaveSeasonData()
        
        self:NotifyAll(string.format("[SEASON] New season started: %s!", template.name), NOTIFY_GENERIC)
        self:NotifyAll(template.description, NOTIFY_GENERIC)
        
        return true
    end
    
    -- End current season
    function GAMEMODE:EndCurrentSeason()
        if not self.SeasonData.currentSeason then return false end
        
        local season = self.SeasonData.currentSeason
        
        -- Award rewards to top players
        self:AwardSeasonRewards()
        
        -- Move to history
        table.insert(self.SeasonData.seasonHistory, {
            id = season.id,
            name = season.name,
            startTime = season.startTime,
            endTime = os.time(),
            participants = table.Count(season.participants),
            topPlayers = self:GetTopSeasonPlayers(3)
        })
        
        -- Keep history limited
        if #self.SeasonData.seasonHistory > 10 then
            table.remove(self.SeasonData.seasonHistory, 1)
        end
        
        self:NotifyAll(string.format("[SEASON] %s has ended!", season.name), NOTIFY_GENERIC)
        
        -- Reset
        if CONFIG.ResetReputationOnNewSeason then
            self:ResetAllReputation()
        end
        
        self.SeasonData.currentSeason = nil
        
        self:SaveSeasonData()
        
        -- Start new season after 24 hours
        timer.Simple(86400, function()
            self:StartNewSeason()
        end)
        
        return true
    end
    
    -- Update season status
    function GAMEMODE:UpdateSeasonStatus()
        if not self.SeasonData.currentSeason then return end
        
        local season = self.SeasonData.currentSeason
        
        -- Check if season expired
        if os.time() >= season.endTime then
            self:EndCurrentSeason()
        end
        
        -- Update leaderboard
        self:UpdateSeasonLeaderboard()
    end
    
    -- Track player progress
    function GAMEMODE:TrackSeasonProgress(ply, challengeType, amount)
        if not self.SeasonData.currentSeason then return end
        if not self:IsValidPlayer(ply) then return end
        
        local steamId = ply:SteamID()
        
        -- Initialize player progress
        if not self.SeasonData.playerProgress[steamId] then
            self.SeasonData.playerProgress[steamId] = {
                steamId = steamId,
                playerName = ply:Nick(),
                challenges = {},
                totalPoints = 0,
                tier = 0
            }
        end
        
        local progress = self.SeasonData.playerProgress[steamId]
        
        -- Update challenge progress
        for _, challenge in ipairs(self.SeasonData.currentSeason.challenges) do
            if challenge.type == challengeType then
                progress.challenges[challenge.id] = (progress.challenges[challenge.id] or 0) + amount
                
                -- Check if challenge completed
                if progress.challenges[challenge.id] >= challenge.requirement and 
                   not progress["completed_" .. challenge.id] then
                    progress["completed_" .. challenge.id] = true
                    progress.totalPoints = progress.totalPoints + 100
                    
                    ply:ChatPrint(string.format("[SEASON] Challenge completed: %s", challenge.name))
                    
                    -- Update tier
                    self:UpdatePlayerSeasonTier(ply)
                end
            end
        end
        
        self:SaveSeasonData()
    end
    
    -- Update player season tier
    function GAMEMODE:UpdatePlayerSeasonTier(ply)
        local steamId = ply:SteamID()
        local progress = self.SeasonData.playerProgress[steamId]
        if not progress then return end
        
        local completedChallenges = 0
        for _, challenge in ipairs(self.SeasonData.currentSeason.challenges) do
            if progress["completed_" .. challenge.id] then
                completedChallenges = completedChallenges + 1
            end
        end
        
        local newTier = 0
        if completedChallenges >= 1 then newTier = 1 end
        if completedChallenges >= 2 then newTier = 2 end
        if completedChallenges >= 3 then newTier = 3 end
        
        if newTier > progress.tier then
            progress.tier = newTier
            ply:ChatPrint(string.format("[SEASON] Tier up! You are now Tier %d", newTier))
        end
    end
    
    -- Award season rewards
    function GAMEMODE:AwardSeasonRewards()
        local topPlayers = self:GetTopSeasonPlayers(10)
        
        for rank, playerData in ipairs(topPlayers) do
            local ply = player.GetBySteamID(playerData.steamId)
            
            -- Determine tier based on rank
            local tier = 1
            if rank <= 3 then tier = 3
            elseif rank <= 7 then tier = 2
            else tier = 1 end
            
            local reward = self.SeasonData.currentSeason.rewards[tier]
            
            if IsValid(ply) then
                -- Award credits
                if reward.credits and self.AddPlayerCredits then
                    self:AddPlayerCredits(ply, reward.credits)
                    ply:ChatPrint(string.format("[SEASON REWARD] %s credits", self:FormatCredits(reward.credits)))
                end
                
                -- Award items
                if reward.items and self.AddItemToInventory then
                    for _, itemId in ipairs(reward.items) do
                        self:AddItemToInventory(ply, itemId, 1)
                        ply:ChatPrint(string.format("[SEASON REWARD] %s", itemId))
                    end
                end
            end
        end
    end
    
    -- Get top season players
    function GAMEMODE:GetTopSeasonPlayers(count)
        local players = {}
        
        for steamId, progress in pairs(self.SeasonData.playerProgress) do
            table.insert(players, progress)
        end
        
        table.sort(players, function(a, b)
            return a.totalPoints > b.totalPoints
        end)
        
        local top = {}
        for i = 1, math.min(count, #players) do
            table.insert(top, players[i])
        end
        
        return top
    end
    
    -- Update season leaderboard
    function GAMEMODE:UpdateSeasonLeaderboard()
        if not self.SeasonData.currentSeason then return end
        
        self.SeasonData.currentSeason.leaderboard = self:GetTopSeasonPlayers(100)
    end
    
    -- Reset all reputation
    function GAMEMODE:ResetAllReputation()
        -- This would reset reputation for all players
        self:NotifyAll("[SEASON] Reputation has been reset for the new season!", NOTIFY_GENERIC)
    end
    
    -- Save season data
    function GAMEMODE:SaveSeasonData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.SeasonData, true)
        file.Write("project_sovereign/seasons.txt", data)
    end
    
    -- Load season data
    function GAMEMODE:LoadSeasonData()
        if file.Exists("project_sovereign/seasons.txt", "DATA") then
            local data = file.Read("project_sovereign/seasons.txt", "DATA")
            if data then
                self.SeasonData = util.JSONToTable(data) or self.SeasonData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_season", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not GAMEMODE.SeasonData.currentSeason then
            ply:ChatPrint("No active season")
            return
        end
        
        local season = GAMEMODE.SeasonData.currentSeason
        local timeLeft = season.endTime - os.time()
        local daysLeft = math.floor(timeLeft / 86400)
        
        ply:ChatPrint("=== " .. season.name .. " ===")
        ply:ChatPrint(season.description)
        ply:ChatPrint(string.format("Time remaining: %d days", daysLeft))
        ply:ChatPrint("\nChallenges:")
        
        for _, challenge in ipairs(season.challenges) do
            ply:ChatPrint(string.format("- %s: %s", challenge.name, challenge.requirement))
        end
    end)
    
    concommand.Add("ps_seasonprogress", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local progress = GAMEMODE.SeasonData.playerProgress[ply:SteamID()]
        if not progress then
            ply:ChatPrint("You have no season progress")
            return
        end
        
        ply:ChatPrint("=== Your Season Progress ===")
        ply:ChatPrint("Total Points: " .. progress.totalPoints)
        ply:ChatPrint("Tier: " .. progress.tier)
        ply:ChatPrint("\nChallenges:")
        
        for _, challenge in ipairs(GAMEMODE.SeasonData.currentSeason.challenges) do
            local current = progress.challenges[challenge.id] or 0
            local status = progress["completed_" .. challenge.id] and "[COMPLETE]" or "[IN PROGRESS]"
            ply:ChatPrint(string.format("%s %s: %d/%d", status, challenge.name, current, challenge.requirement))
        end
    end)
    
    concommand.Add("ps_seasonleaderboard", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Season Leaderboard ===")
        
        local top = GAMEMODE:GetTopSeasonPlayers(10)
        
        for i, playerData in ipairs(top) do
            ply:ChatPrint(string.format("%d. %s - %d points (Tier %d)", 
                i, playerData.playerName, playerData.totalPoints, playerData.tier))
        end
    end)
    
    concommand.Add("ps_startseason", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        GAMEMODE:StartNewSeason()
        ply:ChatPrint("New season started")
    end)
    
    concommand.Add("ps_endseason", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        GAMEMODE:EndCurrentSeason()
        ply:ChatPrint("Season ended")
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Seasons_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeSeasons()
        end)
    end)
    
    -- Track season progress hooks
    hook.Add("PlayerDeath", "Seasons_TrackKills", function(victim, inflictor, attacker)
        if IsValid(attacker) and attacker:IsPlayer() then
            GAMEMODE:TrackSeasonProgress(attacker, "kills", 1)
        end
    end)
end

print("[Phase 8] Seasonal Content System loaded")
