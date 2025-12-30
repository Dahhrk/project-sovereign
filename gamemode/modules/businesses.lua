--[[
    Project Sovereign - Phase 5
    Player Businesses System
    
    Allows players to own and operate businesses for passive income.
]]--

if SERVER then
    GAMEMODE.Businesses = GAMEMODE.Businesses or {}
    GAMEMODE.BusinessData = GAMEMODE.BusinessData or {
        businesses = {},
        playerBusinesses = {}
    }
    
    -- Business types
    local BUSINESS_TYPES = {
        {
            id = "cantina",
            name = "Cantina",
            description = "Entertainment venue for weary travelers",
            cost = 15000,
            baseIncome = 200,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        },
        {
            id = "shop",
            name = "General Store",
            description = "Sell goods and equipment",
            cost = 20000,
            baseIncome = 300,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        },
        {
            id = "workshop",
            name = "Workshop",
            description = "Craft and repair items",
            cost = 25000,
            baseIncome = 250,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        },
        {
            id = "mine",
            name = "Mining Operation",
            description = "Extract valuable resources",
            cost = 30000,
            baseIncome = 400,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        },
        {
            id = "shipyard",
            name = "Shipyard",
            description = "Build and repair ships",
            cost = 50000,
            baseIncome = 600,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        },
        {
            id = "bank",
            name = "Banking Facility",
            description = "Provide loans and financial services",
            cost = 75000,
            baseIncome = 800,
            maxLevel = 5,
            upgradeMultiplier = 1.5
        }
    }
    
    -- Configuration
    local CONFIG = {
        IncomeInterval = 900, -- 15 minutes
        MaxBusinessesPerPlayer = 3,
        UpgradeCostMultiplier = 2.0
    }
    
    -- Initialize business system
    function GAMEMODE:InitializeBusinesses()
        self:LoadBusinessData()
        
        -- Start income timer
        timer.Create("BusinessIncome", CONFIG.IncomeInterval, 0, function()
            self:ProcessBusinessIncome()
        end)
        
        print("[Businesses] Business system initialized")
    end
    
    -- Get business type by ID
    function GAMEMODE:GetBusinessType(typeId)
        for _, bType in ipairs(BUSINESS_TYPES) do
            if bType.id == typeId then
                return bType
            end
        end
        return nil
    end
    
    -- Purchase business
    function GAMEMODE:PurchaseBusiness(ply, businessTypeId, location)
        if not self:IsValidPlayer(ply) then return false, "Invalid player" end
        
        local businessType = self:GetBusinessType(businessTypeId)
        if not businessType then return false, "Invalid business type" end
        
        -- Check player business count
        local playerBizCount = self:GetPlayerBusinessCount(ply)
        if playerBizCount >= CONFIG.MaxBusinessesPerPlayer then
            return false, "Maximum businesses owned"
        end
        
        -- Check if player can afford
        if not self:CanAfford(ply, businessType.cost) then
            return false, "Insufficient credits"
        end
        
        -- Deduct cost
        self:RemovePlayerCredits(ply, businessType.cost)
        
        -- Create business
        local businessId = "biz_" .. ply:SteamID() .. "_" .. os.time()
        
        local business = {
            id = businessId,
            type = businessTypeId,
            owner = ply:SteamID(),
            ownerName = ply:Nick(),
            location = location or Vector(0, 0, 0),
            level = 1,
            createdAt = os.time(),
            lastIncome = CurTime(),
            totalEarned = 0,
            employees = {}
        }
        
        self.BusinessData.businesses[businessId] = business
        
        -- Track player businesses
        if not self.BusinessData.playerBusinesses[ply:SteamID()] then
            self.BusinessData.playerBusinesses[ply:SteamID()] = {}
        end
        table.insert(self.BusinessData.playerBusinesses[ply:SteamID()], businessId)
        
        self:SaveBusinessData()
        
        self:NotifyAll(string.format("%s opened a %s!", ply:Nick(), businessType.name), NOTIFY_GENERIC)
        
        return true, "Business purchased successfully!"
    end
    
    -- Upgrade business
    function GAMEMODE:UpgradeBusiness(ply, businessId)
        local business = self.BusinessData.businesses[businessId]
        if not business then return false, "Business not found" end
        
        if business.owner ~= ply:SteamID() then
            return false, "You don't own this business"
        end
        
        local businessType = self:GetBusinessType(business.type)
        if not businessType then return false, "Invalid business type" end
        
        if business.level >= businessType.maxLevel then
            return false, "Maximum level reached"
        end
        
        -- Calculate upgrade cost
        local upgradeCost = businessType.cost * CONFIG.UpgradeCostMultiplier * business.level
        
        if not self:CanAfford(ply, upgradeCost) then
            return false, "Insufficient credits for upgrade"
        end
        
        -- Perform upgrade
        self:RemovePlayerCredits(ply, upgradeCost)
        business.level = business.level + 1
        
        self:SaveBusinessData()
        
        return true, string.format("Business upgraded to level %d!", business.level)
    end
    
    -- Calculate business income
    function GAMEMODE:CalculateBusinessIncome(business)
        local businessType = self:GetBusinessType(business.type)
        if not businessType then return 0 end
        
        local income = businessType.baseIncome
        
        -- Apply level multiplier
        income = income * math.pow(businessType.upgradeMultiplier, business.level - 1)
        
        -- Apply random variance
        income = income * math.Rand(0.8, 1.2)
        
        return math.floor(income)
    end
    
    -- Process business income
    function GAMEMODE:ProcessBusinessIncome()
        for businessId, business in pairs(self.BusinessData.businesses) do
            local income = self:CalculateBusinessIncome(business)
            
            -- Find owner (if online)
            local owner = player.GetBySteamID(business.owner)
            if IsValid(owner) then
                self:AddPlayerCredits(owner, income)
                owner:ChatPrint(string.format("[Business] Your %s earned %s", 
                    self:GetBusinessType(business.type).name,
                    self:FormatCredits(income)))
            else
                -- Store income for offline collection
                business.pendingIncome = (business.pendingIncome or 0) + income
            end
            
            business.totalEarned = business.totalEarned + income
            business.lastIncome = CurTime()
        end
        
        self:SaveBusinessData()
    end
    
    -- Collect pending income
    function GAMEMODE:CollectPendingIncome(ply)
        local businesses = self:GetPlayerBusinesses(ply)
        local totalPending = 0
        
        for _, business in ipairs(businesses) do
            if business.pendingIncome and business.pendingIncome > 0 then
                totalPending = totalPending + business.pendingIncome
                business.pendingIncome = 0
            end
        end
        
        if totalPending > 0 then
            self:AddPlayerCredits(ply, totalPending)
            self:SaveBusinessData()
            return true, string.format("Collected %s in pending income", self:FormatCredits(totalPending))
        end
        
        return false, "No pending income"
    end
    
    -- Get player businesses
    function GAMEMODE:GetPlayerBusinesses(ply)
        local businesses = {}
        local businessIds = self.BusinessData.playerBusinesses[ply:SteamID()] or {}
        
        for _, businessId in ipairs(businessIds) do
            local business = self.BusinessData.businesses[businessId]
            if business then
                table.insert(businesses, business)
            end
        end
        
        return businesses
    end
    
    -- Get player business count
    function GAMEMODE:GetPlayerBusinessCount(ply)
        return #(self.BusinessData.playerBusinesses[ply:SteamID()] or {})
    end
    
    -- Save business data
    function GAMEMODE:SaveBusinessData()
        if not file.Exists("project_sovereign", "DATA") then
            file.CreateDir("project_sovereign")
        end
        
        local data = util.TableToJSON(self.BusinessData, true)
        file.Write("project_sovereign/businesses.txt", data)
    end
    
    -- Load business data
    function GAMEMODE:LoadBusinessData()
        if file.Exists("project_sovereign/businesses.txt", "DATA") then
            local data = file.Read("project_sovereign/businesses.txt", "DATA")
            if data then
                self.BusinessData = util.JSONToTable(data) or self.BusinessData
            end
        end
    end
    
    -- Commands
    concommand.Add("ps_businesses", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        ply:ChatPrint("=== Available Business Types ===")
        
        for _, bType in ipairs(BUSINESS_TYPES) do
            ply:ChatPrint(string.format("%s - %s", bType.name, GAMEMODE:FormatCredits(bType.cost)))
            ply:ChatPrint("  " .. bType.description)
            ply:ChatPrint(string.format("  Income: %s per interval", GAMEMODE:FormatCredits(bType.baseIncome)))
        end
    end)
    
    concommand.Add("ps_buybusiness", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_buybusiness <businessType>")
            return
        end
        
        local success, message = GAMEMODE:PurchaseBusiness(ply, args[1], ply:GetPos())
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_mybusinesses", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local businesses = GAMEMODE:GetPlayerBusinesses(ply)
        
        if #businesses == 0 then
            ply:ChatPrint("You don't own any businesses")
            return
        end
        
        ply:ChatPrint("=== Your Businesses ===")
        
        for _, business in ipairs(businesses) do
            local bType = GAMEMODE:GetBusinessType(business.type)
            ply:ChatPrint(string.format("%s (Level %d)", bType.name, business.level))
            ply:ChatPrint(string.format("  Total Earned: %s", GAMEMODE:FormatCredits(business.totalEarned)))
            if business.pendingIncome and business.pendingIncome > 0 then
                ply:ChatPrint(string.format("  Pending: %s", GAMEMODE:FormatCredits(business.pendingIncome)))
            end
        end
    end)
    
    concommand.Add("ps_upgradebusiness", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        if not args[1] then
            ply:ChatPrint("Usage: ps_upgradebusiness <businessId>")
            return
        end
        
        local success, message = GAMEMODE:UpgradeBusiness(ply, args[1])
        ply:ChatPrint(message)
    end)
    
    concommand.Add("ps_collectincome", function(ply, cmd, args)
        if not GAMEMODE:IsValidPlayer(ply) then return end
        
        local success, message = GAMEMODE:CollectPendingIncome(ply)
        ply:ChatPrint(message)
    end)
    
    -- Initialize on gamemode load
    hook.Add("Initialize", "Businesses_Initialize", function()
        timer.Simple(1, function()
            GAMEMODE:InitializeBusinesses()
        end)
    end)
end

print("[Phase 5] Player Businesses System loaded")
