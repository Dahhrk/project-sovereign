--[[
    Project Sovereign - Phase 10
    Ecosystem Expansion and Multi-Platform Tools
    
    Web API, cross-server systems, and modding support.
]]--

if SERVER then
    GAMEMODE.Ecosystem = GAMEMODE.Ecosystem or {}
    GAMEMODE.EcosystemData = GAMEMODE.EcosystemData or {
        webAPI = {},
        crossServer = {},
        moddingTools = {},
        leaderboards = {}
    }
    
    -- Configuration
    local CONFIG = {
        EnableWebAPI = true,
        EnableCrossServer = true,
        APIUpdateInterval = 60,
        LeaderboardUpdateInterval = 300,
        MaxLeaderboardEntries = 100
    }
    
    -- Initialize ecosystem
    function GAMEMODE:InitializeEcosystem()
        self:LoadEcosystemData()
        
        -- Initialize web API endpoints
        if CONFIG.EnableWebAPI then
            self:InitializeWebAPI()
        end
        
        -- Initialize cross-server systems
        if CONFIG.EnableCrossServer then
            self:InitializeCrossServer()
        end
        
        -- Initialize leaderboards
        self:InitializeLeaderboards()
        
        -- Update leaderboards periodically
        timer.Create("LeaderboardUpdate", CONFIG.LeaderboardUpdateInterval, 0, function()
            self:UpdateLeaderboards()
        end)
        
        print("[Ecosystem] Multi-platform ecosystem initialized")
    end
    
    -- Initialize Web API
    function GAMEMODE:InitializeWebAPI()
        -- Create API data structure
        self.EcosystemData.webAPI = {
            enabled = true,
            lastUpdate = os.time(),
            endpoints = {},
            stats = {}
        }
        
        -- Export server stats for web
        timer.Create("WebAPIUpdate", CONFIG.APIUpdateInterval, 0, function()
            self:ExportWebAPIData()
        end)
        
        print("[Web API] Web API initialized")
    end
    
    -- Export data for web API
    function GAMEMODE:ExportWebAPIData()
        local apiData = {
            serverInfo = {
                name = GetHostName(),
                map = game.GetMap(),
                maxPlayers = game.MaxPlayers(),
                currentPlayers = #player.GetAll(),
                gamemode = "Project Sovereign",
                version = self.Version or "1.0.0"
            },
            players = {},
            factions = {},
            leaderboards = self.EcosystemData.leaderboards or {},
            territories = {},
            economy = {
                totalWealth = 0,
                averageWealth = 0
            },
            timestamp = os.time()
        }
        
        -- Export player data
        for _, ply in ipairs(player.GetAll()) do
            table.insert(apiData.players, {
                name = ply:Nick(),
                steamId = ply:SteamID(),
                faction = self:GetPlayerFaction(ply),
                rank = self:GetPlayerRank(ply),
                credits = self:GetPlayerCredits(ply),
                kills = ply:GetNWInt("kills", 0),
                deaths = ply:GetNWInt("deaths", 0),
                playtime = ply:GetNWInt("playtime", 0)
            })
        end
        
        -- Export faction data
        for factionId, factionData in pairs(self.Factions or {}) do
            apiData.factions[factionId] = {
                name = factionData.name,
                memberCount = self:GetFactionMemberCount(factionId),
                budget = self:GetFactionBudget and self:GetFactionBudget(factionId) or 0,
                territories = self:GetFactionTerritories and #self:GetFactionTerritories(factionId) or 0
            }
        end
        
        -- Save to file for web access
        if not file.Exists("project_sovereign/web", "DATA") then
            file.CreateDir("project_sovereign/web")
        end
        
        local jsonData = util.TableToJSON(apiData, true)
        file.Write("project_sovereign/web/api_data.json", jsonData)
        
        self.EcosystemData.webAPI.lastUpdate = os.time()
        self.EcosystemData.webAPI.stats = apiData
    end
    
    -- Initialize cross-server systems
    function GAMEMODE:InitializeCrossServer()
        self.EcosystemData.crossServer = {
            enabled = true,
            serverId = tostring(math.random(1000, 9999)),
            connectedServers = {},
            sharedMarket = {},
            transferRequests = {}
        }
        
        print("[Cross-Server] Cross-server systems initialized")
    end
    
    -- Initialize leaderboards
    function GAMEMODE:InitializeLeaderboards()
        self.EcosystemData.leaderboards = {
            wealth = {},
            kills = {},
            reputation = {},
            businesses = {},
            territories = {},
            seasonal = {}
        }
        
        self:UpdateLeaderboards()
    end
    
    -- Update leaderboards
    function GAMEMODE:UpdateLeaderboards()
        -- Wealth leaderboard
        local wealthData = {}
        for _, ply in ipairs(player.GetAll()) do
            table.insert(wealthData, {
                name = ply:Nick(),
                steamId = ply:SteamID(),
                value = self:GetPlayerCredits(ply)
            })
        end
        table.sort(wealthData, function(a, b) return a.value > b.value end)
        self.EcosystemData.leaderboards.wealth = self:TruncateLeaderboard(wealthData)
        
        -- Kills leaderboard
        local killsData = {}
        for _, ply in ipairs(player.GetAll()) do
            table.insert(killsData, {
                name = ply:Nick(),
                steamId = ply:SteamID(),
                value = ply:GetNWInt("kills", 0)
            })
        end
        table.sort(killsData, function(a, b) return a.value > b.value end)
        self.EcosystemData.leaderboards.kills = self:TruncateLeaderboard(killsData)
        
        self:SaveEcosystemData()
    end
    
    -- Truncate leaderboard to max entries
    function GAMEMODE:TruncateLeaderboard(data)
        local truncated = {}
        for i = 1, math.min(CONFIG.MaxLeaderboardEntries, #data) do
            table.insert(truncated, data[i])
        end
        return truncated
    end
    
    -- Get leaderboard
    function GAMEMODE:GetLeaderboard(type)
        return self.EcosystemData.leaderboards[type] or {}
    end
    
    -- Cross-server player transfer
    function GAMEMODE:RequestPlayerTransfer(ply, targetServerId)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        local transferData = {
            steamId = ply:SteamID(),
            playerName = ply:Nick(),
            credits = self:GetPlayerCredits(ply),
            faction = self:GetPlayerFaction(ply),
            rank = self:GetPlayerRank(ply),
            inventory = self:GetPlayerInventory and self:GetPlayerInventory(ply) or {},
            timestamp = os.time(),
            sourceServer = self.EcosystemData.crossServer.serverId,
            targetServer = targetServerId
        }
        
        -- Save transfer request
        local transferId = "transfer_" .. os.time() .. "_" .. math.random(1000, 9999)
        self.EcosystemData.crossServer.transferRequests[transferId] = transferData
        
        self:SaveEcosystemData()
        
        return true, "Transfer request created: " .. transferId
    end
    
    -- Modding tools - Export gamemode structure
    function GAMEMODE:ExportModdingStructure()
        local structure = {
            factions = self.Factions or {},
            config = {
                server = self.Config or {},
                loadouts = self.Loadouts or {}
            },
            modules = {
                "economy", "combat", "territory", "missions",
                "crafting", "reputation", "progression", "businesses",
                "diplomacy", "galaxy", "seasons", "cosmetics"
            },
            hooks = {
                "PlayerSpawn", "PlayerInitialSpawn", "PlayerDeath",
                "PlayerSay", "PlayerConnect", "PlayerDisconnected"
            },
            commands = {},
            api = {
                economy = {
                    "GetPlayerCredits", "AddPlayerCredits", "RemovePlayerCredits"
                },
                factions = {
                    "GetPlayerFaction", "SetPlayerFaction", "GetFactionBudget"
                },
                territory = {
                    "GetTerritories", "CaptureTerritory", "GetFactionTerritories"
                }
            }
        }
        
        -- Export to modding folder
        if not file.Exists("project_sovereign/modding", "DATA") then
            file.CreateDir("project_sovereign/modding")
        end
        
        local jsonData = util.TableToJSON(structure, true)
        file.Write("project_sovereign/modding/gamemode_structure.json", jsonData)
        
        return true
    end
    
    -- Create modding template
    function GAMEMODE:CreateModdingTemplate(modName)
        local template = {
            name = modName,
            version = "1.0.0",
            author = "Unknown",
            description = "A custom mod for Project Sovereign",
            dependencies = {},
            hooks = {},
            commands = {},
            config = {}
        }
        
        local templatePath = "project_sovereign/modding/templates/" .. modName .. ".json"
        
        if not file.Exists("project_sovereign/modding/templates", "DATA") then
            file.CreateDir("project_sovereign/modding/templates")
        end
        
        local jsonData = util.TableToJSON(template, true)
        file.Write(templatePath, jsonData)
        
        return true, "Template created at: " .. templatePath
    end
    
    -- Get faction member count
    function GAMEMODE:GetFactionMemberCount(factionId)
        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            if self:GetPlayerFaction(ply) == factionId then
                count = count + 1
            end
        end
        return count
    end
    
    -- Save ecosystem data
    function GAMEMODE:SaveEcosystemData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.EcosystemData, true)
        file.Write("project_sovereign/ecosystem.txt", data)
    end
    
    -- Load ecosystem data
    function GAMEMODE:LoadEcosystemData()
        if file.Exists("project_sovereign/ecosystem.txt", "DATA") then
            local data = file.Read("project_sovereign/ecosystem.txt", "DATA")
            if data then
                self.EcosystemData = util.JSONToTable(data) or self.EcosystemData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_leaderboard", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local type = args[1] or "wealth"
        local leaderboard = GAMEMODE:GetLeaderboard(type)
        
        ply:ChatPrint("=== " .. type:upper() .. " Leaderboard ===")
        
        for i, entry in ipairs(leaderboard) do
            if i <= 10 then
                ply:ChatPrint(string.format("%d. %s - %s", i, entry.name, 
                    GAMEMODE:FormatCredits(entry.value or 0)))
            end
        end
        
        ply:ChatPrint("\nTypes: wealth, kills, reputation, businesses, territories")
    end)
    
    concommand.Add("ps_webapi", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        GAMEMODE:ExportWebAPIData()
        ply:ChatPrint("Web API data exported")
        ply:ChatPrint("Location: data/project_sovereign/web/api_data.json")
    end)
    
    concommand.Add("ps_exportstructure", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        GAMEMODE:ExportModdingStructure()
        ply:ChatPrint("Gamemode structure exported for modding")
        ply:ChatPrint("Location: data/project_sovereign/modding/gamemode_structure.json")
    end)
    
    concommand.Add("ps_createmodtemplate", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not GAMEMODE:HasPermission(ply, "admin") then
            ply:ChatPrint("Admin only command")
            return
        end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_createmodtemplate <modName>")
            return
        end
        
        local success, message = GAMEMODE:CreateModdingTemplate(args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_transferserver", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_transferserver <targetServerId>")
            return
        end
        
        local success, message = GAMEMODE:RequestPlayerTransfer(ply, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_serverstats", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Server Statistics ===")
        ply:ChatPrint("Players: " .. #player.GetAll() .. "/" .. game.MaxPlayers())
        ply:ChatPrint("Map: " .. game.GetMap())
        ply:ChatPrint("Gamemode: Project Sovereign")
        
        if GAMEMODE.EcosystemData.webAPI and GAMEMODE.EcosystemData.webAPI.stats then
            local stats = GAMEMODE.EcosystemData.webAPI.stats
            if stats.economy then
                ply:ChatPrint("Total Wealth: " .. GAMEMODE:FormatCredits(stats.economy.totalWealth or 0))
            end
        end
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Ecosystem_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeEcosystem()
        end)
    end)
end

print("[Phase 10] Ecosystem Expansion System loaded")
