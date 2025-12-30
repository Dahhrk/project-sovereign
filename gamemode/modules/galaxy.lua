--[[
    Project Sovereign - Phase 4
    Procedural Galaxy Generation System
    
    Creates a dynamic galaxy with planets, resources, and NPCs.
]]--

if SERVER then
    GAMEMODE.Galaxy = GAMEMODE.Galaxy or {}
    GAMEMODE.GalaxyData = GAMEMODE.GalaxyData or {
        sectors = {},
        planets = {},
        resources = {},
        npcs = {},
        seed = 0
    }
    
    -- Configuration
    local CONFIG = {
        SectorCount = 25,
        PlanetsPerSector = 3,
        ResourceTypes = 8,
        NPCFactionsCount = 5,
        GalaxyRadius = 10000
    }
    
    -- Planet types
    local PLANET_TYPES = {
        {id = "desert", name = "Desert", resources = {"minerals", "gas"}, rarity = "common"},
        {id = "ice", name = "Ice", resources = {"water", "crystals"}, rarity = "common"},
        {id = "forest", name = "Forest", resources = {"organic", "rare_materials"}, rarity = "uncommon"},
        {id = "volcanic", name = "Volcanic", resources = {"metals", "energy"}, rarity = "uncommon"},
        {id = "oceanic", name = "Oceanic", resources = {"water", "organic"}, rarity = "common"},
        {id = "urban", name = "Urban", resources = {"technology", "rare_materials"}, rarity = "rare"},
        {id = "crystal", name = "Crystal", resources = {"crystals", "energy"}, rarity = "rare"},
        {id = "ancient", name = "Ancient Ruin", resources = {"artifacts", "technology"}, rarity = "legendary"}
    }
    
    -- Resource types
    local RESOURCE_TYPES = {
        {id = "minerals", name = "Minerals", value = 100},
        {id = "gas", name = "Gas", value = 150},
        {id = "water", name = "Water", value = 50},
        {id = "crystals", name = "Crystals", value = 300},
        {id = "organic", name = "Organic Matter", value = 80},
        {id = "metals", name = "Metals", value = 200},
        {id = "energy", name = "Energy Cores", value = 400},
        {id = "technology", name = "Technology", value = 500},
        {id = "rare_materials", name = "Rare Materials", value = 600},
        {id = "artifacts", name = "Artifacts", value = 1000}
    }
    
    -- NPC faction types
    local NPC_FACTIONS = {
        {id = "traders", name = "Trade Consortium", hostile = false, resources = "high"},
        {id = "pirates", name = "Pirate Clans", hostile = true, resources = "medium"},
        {id = "mercenaries", name = "Mercenary Guild", hostile = false, resources = "medium"},
        {id = "scavengers", name = "Scavenger Collective", hostile = false, resources = "low"},
        {id = "cultists", name = "Ancient Cultists", hostile = true, resources = "high"}
    }
    
    -- Initialize galaxy
    function GAMEMODE:InitializeGalaxy()
        self:LoadGalaxyData()
        
        -- Generate galaxy if not exists
        if table.IsEmpty(self.GalaxyData.sectors) then
            self:GenerateGalaxy()
        end
        
        print("[Galaxy] Galaxy system initialized with " .. table.Count(self.GalaxyData.sectors) .. " sectors")
    end
    
    -- Generate procedural galaxy
    function GAMEMODE:GenerateGalaxy()
        math.randomseed(os.time())
        self.GalaxyData.seed = math.random(1, 999999)
        math.randomseed(self.GalaxyData.seed)
        
        print("[Galaxy] Generating galaxy with seed: " .. self.GalaxyData.seed)
        
        -- Generate sectors
        for i = 1, CONFIG.SectorCount do
            local sectorId = "sector_" .. i
            local angle = (i / CONFIG.SectorCount) * math.pi * 2
            local distance = math.random(2000, CONFIG.GalaxyRadius)
            
            local sector = {
                id = sectorId,
                name = self:GenerateSectorName(),
                position = Vector(
                    math.cos(angle) * distance,
                    math.sin(angle) * distance,
                    math.random(-1000, 1000)
                ),
                dangerLevel = math.random(1, 10),
                planets = {}
            }
            
            -- Generate planets in sector
            for j = 1, math.random(1, CONFIG.PlanetsPerSector) do
                local planet = self:GeneratePlanet(sectorId, j)
                table.insert(sector.planets, planet.id)
                self.GalaxyData.planets[planet.id] = planet
            end
            
            self.GalaxyData.sectors[sectorId] = sector
        end
        
        -- Generate NPC presence
        self:GenerateNPCPresence()
        
        self:SaveGalaxyData()
    end
    
    -- Generate planet
    function GAMEMODE:GeneratePlanet(sectorId, index)
        local planetType = PLANET_TYPES[math.random(1, #PLANET_TYPES)]
        local planetId = sectorId .. "_planet_" .. index
        
        local planet = {
            id = planetId,
            name = self:GeneratePlanetName(),
            type = planetType.id,
            rarity = planetType.rarity,
            sector = sectorId,
            resources = {},
            population = math.random(0, 1000000),
            hasBase = math.random() > 0.7, -- 30% chance of base
            owner = nil
        }
        
        -- Generate resources
        for _, resourceId in ipairs(planetType.resources) do
            planet.resources[resourceId] = math.random(100, 10000)
        end
        
        return planet
    end
    
    -- Generate sector name
    function GAMEMODE:GenerateSectorName()
        local prefixes = {"Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Theta", "Omega"}
        local suffixes = {"Prime", "Secundus", "Tertius", "Majoris", "Minoris", "Nebula", "Expanse"}
        
        return prefixes[math.random(1, #prefixes)] .. " " .. suffixes[math.random(1, #suffixes)]
    end
    
    -- Generate planet name
    function GAMEMODE:GeneratePlanetName()
        local consonants = {"b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "x", "z"}
        local vowels = {"a", "e", "i", "o", "u"}
        
        local name = ""
        local length = math.random(4, 8)
        
        for i = 1, length do
            if i % 2 == 1 then
                name = name .. consonants[math.random(1, #consonants)]
            else
                name = name .. vowels[math.random(1, #vowels)]
            end
        end
        
        -- Capitalize first letter
        name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
        
        -- Add roman numeral sometimes
        if math.random() > 0.5 then
            local numerals = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"}
            name = name .. " " .. numerals[math.random(1, #numerals)]
        end
        
        return name
    end
    
    -- Generate NPC presence in galaxy
    function GAMEMODE:GenerateNPCPresence()
        for _, npcFaction in ipairs(NPC_FACTIONS) do
            -- Assign random sectors to NPC faction
            local sectorCount = math.random(2, 5)
            local assignedSectors = {}
            
            for i = 1, sectorCount do
                local randomSectorId = "sector_" .. math.random(1, CONFIG.SectorCount)
                table.insert(assignedSectors, randomSectorId)
            end
            
            self.GalaxyData.npcs[npcFaction.id] = {
                id = npcFaction.id,
                name = npcFaction.name,
                hostile = npcFaction.hostile,
                sectors = assignedSectors,
                strength = math.random(50, 200),
                resources = npcFaction.resources
            }
        end
    end
    
    -- Get sector by ID
    function GAMEMODE:GetSector(sectorId)
        return self.GalaxyData.sectors[sectorId]
    end
    
    -- Get planet by ID
    function GAMEMODE:GetPlanet(planetId)
        return self.GalaxyData.planets[planetId]
    end
    
    -- Get all sectors
    function GAMEMODE:GetAllSectors()
        return self.GalaxyData.sectors
    end
    
    -- Get planets in sector
    function GAMEMODE:GetSectorPlanets(sectorId)
        local sector = self:GetSector(sectorId)
        if not sector then return {} end
        
        local planets = {}
        for _, planetId in ipairs(sector.planets) do
            table.insert(planets, self.GalaxyData.planets[planetId])
        end
        return planets
    end
    
    -- Harvest resources from planet
    function GAMEMODE:HarvestPlanetResources(ply, planetId, resourceId)
        local planet = self:GetPlanet(planetId)
        if not planet then return false, "Planet not found" end
        
        if not planet.resources[resourceId] or planet.resources[resourceId] <= 0 then
            return false, "Resource depleted"
        end
        
        -- Harvest amount based on skill/equipment
        local harvestAmount = math.random(10, 50)
        harvestAmount = math.min(harvestAmount, planet.resources[resourceId])
        
        planet.resources[resourceId] = planet.resources[resourceId] - harvestAmount
        
        -- Add to player inventory
        if self.AddItemToInventory then
            self:AddItemToInventory(ply, resourceId, harvestAmount)
        end
        
        self:SaveGalaxyData()
        return true, "Harvested " .. harvestAmount .. " " .. resourceId
    end
    
    -- Save galaxy data
    function GAMEMODE:SaveGalaxyData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.GalaxyData, true)
        file.Write("project_sovereign/galaxy.txt", data)
    end
    
    -- Load galaxy data
    function GAMEMODE:LoadGalaxyData()
        if file.Exists("project_sovereign/galaxy.txt", "DATA") then
            local data = file.Read("project_sovereign/galaxy.txt", "DATA")
            if data then
                self.GalaxyData = util.JSONToTable(data) or self.GalaxyData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_galaxy", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Galaxy Overview ===")
        ply:ChatPrint("Total Sectors: " .. table.Count(GAMEMODE.GalaxyData.sectors))
        ply:ChatPrint("Total Planets: " .. table.Count(GAMEMODE.GalaxyData.planets))
        ply:ChatPrint("Galaxy Seed: " .. GAMEMODE.GalaxyData.seed)
        ply:ChatPrint("\nUse /sectors to view all sectors")
    end)
    
    concommand.Add("ps_sectors", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Galaxy Sectors ===")
        
        for sectorId, sector in pairs(GAMEMODE.GalaxyData.sectors) do
            ply:ChatPrint(string.format("%s - Danger: %d, Planets: %d",
                sector.name, sector.dangerLevel, #sector.planets))
        end
    end)
    
    concommand.Add("ps_sectorinfo", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        if not args[1] then
            ply:ChatPrint("Usage: ps_sectorinfo <sectorId>")
            return
        end
        
        local sector = GAMEMODE:GetSector(args[1])
        if not sector then
            ply:ChatPrint("Sector not found")
            return
        end
        
        ply:ChatPrint("=== " .. sector.name .. " ===")
        ply:ChatPrint("Danger Level: " .. sector.dangerLevel)
        ply:ChatPrint("\nPlanets:")
        
        local planets = GAMEMODE:GetSectorPlanets(args[1])
        for _, planet in ipairs(planets) do
            ply:ChatPrint(string.format("- %s (%s)", planet.name, planet.type))
        end
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Galaxy_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeGalaxy()
        end)
    end)
end

print("[Phase 4] Procedural Galaxy System loaded")
