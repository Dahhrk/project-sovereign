--[[
    Marketplace Module - Phase 2
    Player-to-player marketplace for items and services
]]--

-- Initialize marketplace data
GM.Marketplace = GM.Marketplace or {
    listings = {},
    nextListingID = 1
}

-- Initialize marketplace
local function InitMarketplace()
    GAMEMODE:Log("Marketplace module initialized")
end

if SERVER then
    hook.Add("Initialize", "ProjectSovereign_InitMarketplace", InitMarketplace)
end

-- Get marketplace data path
local function GetMarketplaceDataPath()
    return "project_sovereign/marketplace.txt"
end

-- Save marketplace data
function GM:SaveMarketplace()
    if not SERVER then return false end
    
    local data = {
        listings = self.Marketplace.listings,
        nextListingID = self.Marketplace.nextListingID
    }
    
    local json = util.TableToJSON(data, true)
    if not json then
        self:ErrorLog("Failed to serialize marketplace data")
        return false
    end
    
    file.CreateDir("project_sovereign")
    file.Write(GetMarketplaceDataPath(), json)
    
    self:DebugLog("Saved marketplace data")
    return true
end

-- Load marketplace data
function GM:LoadMarketplace()
    if not SERVER then return false end
    
    local filePath = GetMarketplaceDataPath()
    
    if not file.Exists(filePath, "DATA") then
        self:Log("No marketplace data found, starting fresh")
        return false
    end
    
    local json = file.Read(filePath, "DATA")
    if not json then
        self:ErrorLog("Failed to read marketplace data")
        return false
    end
    
    local data = util.JSONToTable(json)
    if not data then
        self:ErrorLog("Failed to parse marketplace data")
        return false
    end
    
    self.Marketplace.listings = data.listings or {}
    self.Marketplace.nextListingID = data.nextListingID or 1
    
    self:Log("Loaded marketplace data successfully")
    return true
end

-- Create a new listing
function GM:CreateListing(ply, itemName, price, description)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    if not itemName or itemName == "" then
        return false, "Invalid item name"
    end
    
    if not price or price <= 0 then
        return false, "Invalid price"
    end
    
    local listingID = self.Marketplace.nextListingID
    self.Marketplace.nextListingID = self.Marketplace.nextListingID + 1
    
    local listing = {
        id = listingID,
        seller = ply:SteamID(),
        sellerName = ply:Nick(),
        itemName = itemName,
        price = price,
        description = description or "",
        timestamp = os.time()
    }
    
    self.Marketplace.listings[listingID] = listing
    self:SaveMarketplace()
    
    self:Log(string.format("%s listed '%s' for %d credits (Listing #%d)", 
        ply:Nick(), itemName, price, listingID))
    
    return true, listingID
end

-- Buy a listing
function GM:BuyListing(ply, listingID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local listing = self.Marketplace.listings[listingID]
    if not listing then
        return false, "Listing not found"
    end
    
    -- Cannot buy your own listing
    if listing.seller == ply:SteamID() then
        return false, "Cannot buy your own listing"
    end
    
    -- Check if buyer can afford
    if not self:CanAfford(ply, listing.price) then
        return false, string.format("Insufficient credits. Need: %s, Have: %s",
            self:FormatCredits(listing.price),
            self:FormatCredits(self:GetPlayerCredits(ply)))
    end
    
    -- Find seller
    local seller = nil
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID() == listing.seller then
            seller = p
            break
        end
    end
    
    -- Remove credits from buyer
    if not self:RemovePlayerCredits(ply, listing.price) then
        return false, "Transaction failed"
    end
    
    -- Add credits to seller (even if offline, they'll get it next time)
    if seller and self:IsValidPlayer(seller) then
        self:AddPlayerCredits(seller, listing.price)
        self:Notify(seller, string.format("Your listing #%d (%s) was purchased by %s for %s",
            listingID, listing.itemName, ply:Nick(), self:FormatCredits(listing.price)), NOTIFY_HINT)
    end
    
    -- Remove listing
    self.Marketplace.listings[listingID] = nil
    self:SaveMarketplace()
    
    self:Log(string.format("%s purchased listing #%d (%s) from %s for %d credits",
        ply:Nick(), listingID, listing.itemName, listing.sellerName, listing.price))
    
    return true, listing.itemName
end

-- Cancel a listing
function GM:CancelListing(ply, listingID)
    if not self:IsValidPlayer(ply) then
        return false, "Invalid player"
    end
    
    local listing = self.Marketplace.listings[listingID]
    if not listing then
        return false, "Listing not found"
    end
    
    -- Can only cancel your own listing
    if listing.seller ~= ply:SteamID() then
        return false, "You can only cancel your own listings"
    end
    
    self.Marketplace.listings[listingID] = nil
    self:SaveMarketplace()
    
    self:Log(string.format("%s cancelled listing #%d (%s)",
        ply:Nick(), listingID, listing.itemName))
    
    return true
end

-- Get all active listings
function GM:GetActiveListings()
    return self.Marketplace.listings
end

-- Get player's listings
function GM:GetPlayerListings(ply)
    if not self:IsValidPlayer(ply) then
        return {}
    end
    
    local playerListings = {}
    for id, listing in pairs(self.Marketplace.listings) do
        if listing.seller == ply:SteamID() then
            playerListings[id] = listing
        end
    end
    
    return playerListings
end

-- Commands

-- List item command
GM:RegisterCommand("listitem", function(ply, args)
    if #args < 2 then
        GAMEMODE:Notify(ply, "Usage: /listitem <item> <price> [description]", NOTIFY_ERROR)
        return
    end
    
    local itemName = args[1]
    local price = tonumber(args[2])
    
    if not price or price <= 0 then
        GAMEMODE:Notify(ply, "Invalid price", NOTIFY_ERROR)
        return
    end
    
    local description = ""
    if #args > 2 then
        table.remove(args, 1)
        table.remove(args, 1)
        description = table.concat(args, " ")
    end
    
    local success, result = GAMEMODE:CreateListing(ply, itemName, price, description)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Listed '%s' for %s (Listing #%d)", 
            itemName, GAMEMODE:FormatCredits(price), result), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. result, NOTIFY_ERROR)
    end
end, false, "List an item for sale on the marketplace")

-- Buy item command
GM:RegisterCommand("buyitem", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /buyitem <listingID>", NOTIFY_ERROR)
        return
    end
    
    local listingID = tonumber(args[1])
    if not listingID then
        GAMEMODE:Notify(ply, "Invalid listing ID", NOTIFY_ERROR)
        return
    end
    
    local success, result = GAMEMODE:BuyListing(ply, listingID)
    
    if success then
        GAMEMODE:Notify(ply, string.format("Successfully purchased: %s", result), NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. result, NOTIFY_ERROR)
    end
end, false, "Purchase an item from the marketplace")

-- Cancel listing command
GM:RegisterCommand("cancelitem", function(ply, args)
    if #args < 1 then
        GAMEMODE:Notify(ply, "Usage: /cancelitem <listingID>", NOTIFY_ERROR)
        return
    end
    
    local listingID = tonumber(args[1])
    if not listingID then
        GAMEMODE:Notify(ply, "Invalid listing ID", NOTIFY_ERROR)
        return
    end
    
    local success, result = GAMEMODE:CancelListing(ply, listingID)
    
    if success then
        GAMEMODE:Notify(ply, "Listing cancelled successfully", NOTIFY_GENERIC)
    else
        GAMEMODE:Notify(ply, "Error: " .. result, NOTIFY_ERROR)
    end
end, false, "Cancel your marketplace listing")

-- View marketplace command
GM:RegisterCommand("marketplace", function(ply, args)
    local listings = GAMEMODE:GetActiveListings()
    
    if table.Count(listings) == 0 then
        GAMEMODE:Notify(ply, "The marketplace is empty", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== MARKETPLACE ===")
    for id, listing in pairs(listings) do
        ply:ChatPrint(string.format("#%d | %s - %s | Seller: %s",
            id, listing.itemName, GAMEMODE:FormatCredits(listing.price), listing.sellerName))
        if listing.description ~= "" then
            ply:ChatPrint("  " .. listing.description)
        end
    end
    ply:ChatPrint("==================")
end, false, "View all marketplace listings")

-- View your listings command
GM:RegisterCommand("mylistings", function(ply, args)
    local listings = GAMEMODE:GetPlayerListings(ply)
    
    if table.Count(listings) == 0 then
        GAMEMODE:Notify(ply, "You have no active listings", NOTIFY_HINT)
        return
    end
    
    ply:ChatPrint("=== YOUR LISTINGS ===")
    for id, listing in pairs(listings) do
        ply:ChatPrint(string.format("#%d | %s - %s",
            id, listing.itemName, GAMEMODE:FormatCredits(listing.price)))
        if listing.description ~= "" then
            ply:ChatPrint("  " .. listing.description)
        end
    end
    ply:ChatPrint("====================")
end, false, "View your marketplace listings")

-- Load marketplace on server init
if SERVER then
    hook.Add("Initialize", "ProjectSovereign_LoadMarketplace", function()
        GAMEMODE:LoadMarketplace()
    end)
    
    -- Auto-save marketplace periodically
    timer.Create("ProjectSovereign_MarketplaceAutoSave", 300, 0, function()
        GAMEMODE:SaveMarketplace()
    end)
end
