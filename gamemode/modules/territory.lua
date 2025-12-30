--[[
    Project Sovereign - Phase 3
    Territory Control System
    
    Handles territory ownership, capture mechanics, and faction control points.
]]--

if SERVER then
    -- Territory data structure
    GAMEMODE.Territories = GAMEMODE.Territories or {}
    GAMEMODE.TerritoryData = GAMEMODE.TerritoryData or {
        territories = {},
        captureProgress = {},
        lastUpdate = CurTime()
    }
    
    -- Configuration
    local CONFIG = {
        CaptureTime = 300, -- 5 minutes to capture
        CaptureRadius = 500, -- Capture radius
        IncomeInterval = 600, -- 10 minutes between income
        MinPlayersToCapture = 1, -- Minimum players needed
        ContestRadius = 800, -- Radius to contest capture
        PointsPerCapture = 100, -- Faction points per capture
        IncomePerTerritory = 500 -- Credits per territory per interval
    }
    
    -- Territory types with different bonuses
    local TERRITORY_TYPES = {
        {id = "mining", name = "Mining Outpost", income = 750, bonus = "resources"},
        {id = "military", name = "Military Base", income = 500, bonus = "combat"},
        {id = "trade", name = "Trade Hub", income = 1000, bonus = "economy"},
        {id = "research", name = "Research Facility", income = 600, bonus = "tech"},
        {id = "spaceport", name = "Spaceport", income = 800, bonus = "mobility"}
    }
    
    -- Define default territories
    local DEFAULT_TERRITORIES = {
        {
            id = "republic_capitol",
            name = "Republic Capitol",
            position = Vector(0, 0, 0),
            type = "military",
            owner = "Republic",
            capturable = false, -- Home territories can't be captured
            radius = 600
        },
        {
            id = "cis_headquarters",
            name = "CIS Headquarters",
            position = Vector(2000, 0, 0),
            type = "military",
            owner = "CIS",
            capturable = false,
            radius = 600
        },
        {
            id = "neutral_outpost_1",
            name = "Neutral Mining Colony",
            position = Vector(1000, 1000, 0),
            type = "mining",
            owner = nil,
            capturable = true,
            radius = 400
        },
        {
            id = "neutral_outpost_2",
            name = "Trade Station Alpha",
            position = Vector(-1000, 1000, 0),
            type = "trade",
            owner = nil,
            capturable = true,
            radius = 400
        },
        {
            id = "neutral_outpost_3",
            name = "Research Complex Beta",
            position = Vector(1000, -1000, 0),
            type = "research",
            owner = nil,
            capturable = true,
            radius = 400
        }
    }
    
    -- Initialize territory system
    function GAMEMODE:InitializeTerritories()
        self:LoadTerritoryData()
        
        -- Create default territories if none exist
        if table.IsEmpty(self.TerritoryData.territories) then
            for _, terr in ipairs(DEFAULT_TERRITORIES) do
                self.TerritoryData.territories[terr.id] = {
                    id = terr.id,
                    name = terr.name,
                    position = terr.position,
                    type = terr.type,
                    owner = terr.owner,
                    capturable = terr.capturable,
                    radius = terr.radius,
                    capturedAt = 0,
                    lastIncome = CurTime()
                }
            end
            self:SaveTerritoryData()
        end
        
        -- Start territory update timer (5 seconds for better performance)
        timer.Create("TerritoryUpdate", 5, 0, function()
            self:UpdateTerritories()
        end)
        
        -- Start income timer
        timer.Create("TerritoryIncome", CONFIG.IncomeInterval, 0, function()
            self:ProcessTerritoryIncome()
        end)
        
        print("[Territory] Territory system initialized with " .. table.Count(self.TerritoryData.territories) .. " territories")
    end
    
    -- Update territory capture progress
    function GAMEMODE:UpdateTerritories()
        for territoryId, territory in pairs(self.TerritoryData.territories) do
            if territory.capturable then
                local playersInRadius = {}
                local factionCounts = {}
                
                -- Count players in capture radius
                for _, ply in ipairs(player.GetAll()) do
                    if ply:Alive() and ply:GetPos():Distance(territory.position) <= territory.radius then
                        local faction = self:GetPlayerFaction(ply)
                        if faction then
                            table.insert(playersInRadius, ply)
                            factionCounts[faction] = (factionCounts[faction] or 0) + 1
                        end
                    end
                end
                
                -- Check for capture progress
                local dominantFaction = nil
                local dominantCount = 0
                local isContested = false
                
                for faction, count in pairs(factionCounts) do
                    if count > dominantCount then
                        dominantFaction = faction
                        dominantCount = count
                    elseif count == dominantCount and count > 0 then
                        isContested = true
                    end
                end
                
                -- Check for contestation
                if table.Count(factionCounts) > 1 then
                    isContested = true
                end
                
                -- Update capture progress
                if dominantFaction and not isContested and dominantCount >= CONFIG.MinPlayersToCapture then
                    -- Different faction is capturing
                    if territory.owner ~= dominantFaction then
                        self.TerritoryData.captureProgress[territoryId] = self.TerritoryData.captureProgress[territoryId] or {
                            faction = dominantFaction,
                            progress = 0,
                            startTime = CurTime()
                        }
                        
                        local capture = self.TerritoryData.captureProgress[territoryId]
                        if capture.faction == dominantFaction then
                            -- Adjusted for 5-second update interval
                            capture.progress = capture.progress + (5 / CONFIG.CaptureTime)
                            
                            -- Check if captured
                            if capture.progress >= 1 then
                                self:CaptureTerritory(territoryId, dominantFaction)
                                self.TerritoryData.captureProgress[territoryId] = nil
                            end
                        else
                            -- Reset if different faction
                            self.TerritoryData.captureProgress[territoryId] = {
                                faction = dominantFaction,
                                progress = 0,
                                startTime = CurTime()
                            }
                        end
                    end
                else
                    -- No capture or contested
                    if self.TerritoryData.captureProgress[territoryId] then
                        -- Decay progress
                        self.TerritoryData.captureProgress[territoryId].progress = 
                            math.max(0, self.TerritoryData.captureProgress[territoryId].progress - (0.5 / CONFIG.CaptureTime))
                        
                        if self.TerritoryData.captureProgress[territoryId].progress <= 0 then
                            self.TerritoryData.captureProgress[territoryId] = nil
                        end
                    end
                end
            end
        end
    end
    
    -- Capture territory
    function GAMEMODE:CaptureTerritory(territoryId, faction)
        local territory = self.TerritoryData.territories[territoryId]
        if not territory then return end
        
        local oldOwner = territory.owner
        territory.owner = faction
        territory.capturedAt = CurTime()
        
        -- Award faction points
        if self.AddFactionBudget then
            self:AddFactionBudget(faction, CONFIG.PointsPerCapture)
        end
        
        -- Notify all players
        self:NotifyAll(string.format("%s has captured %s!", faction, territory.name), NOTIFY_GENERIC)
        
        -- Log the capture
        self:LogEvent("TERRITORY", string.format("%s captured %s (previously: %s)", 
            faction, territory.name, oldOwner or "Neutral"))
        
        self:SaveTerritoryData()
    end
    
    -- Process territory income
    function GAMEMODE:ProcessTerritoryIncome()
        local factionIncome = {}
        
        for _, territory in pairs(self.TerritoryData.territories) do
            if territory.owner then
                local income = CONFIG.IncomePerTerritory
                
                -- Apply territory type bonus
                for _, tType in ipairs(TERRITORY_TYPES) do
                    if tType.id == territory.type then
                        income = tType.income
                        break
                    end
                end
                
                factionIncome[territory.owner] = (factionIncome[territory.owner] or 0) + income
                territory.lastIncome = CurTime()
            end
        end
        
        -- Distribute income to faction budgets
        for faction, income in pairs(factionIncome) do
            if self.AddFactionBudget then
                self:AddFactionBudget(faction, income)
                self:NotifyAll(string.format("%s earned %s credits from territories", 
                    faction, self:FormatCredits(income)), NOTIFY_GENERIC)
            end
        end
        
        self:SaveTerritoryData()
    end
    
    -- Get territory info
    function GAMEMODE:GetTerritory(territoryId)
        return self.TerritoryData.territories[territoryId]
    end
    
    -- Get all territories
    function GAMEMODE:GetTerritories()
        return self.TerritoryData.territories
    end
    
    -- Get territories owned by faction
    function GAMEMODE:GetFactionTerritories(faction)
        local territories = {}
        for id, territory in pairs(self.TerritoryData.territories) do
            if territory.owner == faction then
                table.insert(territories, territory)
            end
        end
        return territories
    end
    
    -- Save territory data
    function GAMEMODE:SaveTerritoryData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.TerritoryData, true)
        file.Write("project_sovereign/territories.txt", data)
    end
    
    -- Load territory data
    function GAMEMODE:LoadTerritoryData()
        if file.Exists("project_sovereign/territories.txt", "DATA") then
            local data = file.Read("project_sovereign/territories.txt", "DATA")
            if data then
                self.TerritoryData = util.JSONToTable(data) or self.TerritoryData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_territories", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Territory Status ===")
        
        local factionCounts = {}
        for _, territory in pairs(GAMEMODE.TerritoryData.territories) do
            local owner = territory.owner or "Neutral"
            factionCounts[owner] = (factionCounts[owner] or 0) + 1
            
            local status = string.format("%s - Owner: %s (%s)", 
                territory.name, owner, territory.type)
            ply:ChatPrint(status)
        end
        
        ply:ChatPrint("\n=== Territory Count by Faction ===")
        for faction, count in pairs(factionCounts) do
            ply:ChatPrint(string.format("%s: %d territories", faction, count))
        end
    end)
    
    concommand.Add("ps_captureinfo", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Active Capture Progress ===")
        
        if table.IsEmpty(GAMEMODE.TerritoryData.captureProgress) then
            ply:ChatPrint("No territories being captured")
            return
        end
        
        for territoryId, capture in pairs(GAMEMODE.TerritoryData.captureProgress) do
            local territory = GAMEMODE.TerritoryData.territories[territoryId]
            if territory then
                ply:ChatPrint(string.format("%s - %s: %.1f%% captured", 
                    territory.name, capture.faction, capture.progress * 100))
            end
        end
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Territory_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeTerritories()
        end)
    end)
end

print("[Phase 3] Territory Control System loaded")
