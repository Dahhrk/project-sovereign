--[[
    Project Sovereign - Phase 1 Gamemode
    Main Initialization File
    
    This file initializes all core systems and modules for the gamemode.
]]--

-- Define gamemode information
GM.Name = "Project Sovereign"
GM.Author = "Dahhrk"
GM.Email = ""
GM.Website = ""
GM.Version = "1.0.0 - Phase 1"

-- Derive gamemode base
DeriveGamemode("sandbox")

-- Print startup message
print("======================================")
print("  PROJECT SOVEREIGN - PHASE 1")
print("  Version: " .. GM.Version)
print("  Loading gamemode...")
print("======================================")

-- Helper function to include files based on prefix
local function IncludeFile(file)
    local prefix = string.Left(file, 3)
    
    if prefix == "sh_" then
        -- Shared files
        if SERVER then
            AddCSLuaFile(file)
        end
        include(file)
        return "SHARED"
    elseif prefix == "cl_" then
        -- Client files
        if SERVER then
            AddCSLuaFile(file)
        else
            include(file)
        end
        return "CLIENT"
    elseif prefix == "sv_" then
        -- Server files
        if SERVER then
            include(file)
        end
        return "SERVER"
    else
        -- No prefix - treat as shared
        if SERVER then
            AddCSLuaFile(file)
        end
        include(file)
        return "SHARED"
    end
end

-- Helper function to load directory
local function LoadDirectory(dir, recursive)
    local files, folders = file.Find(dir .. "/*", "LUA")
    
    -- Load files
    for _, fileName in ipairs(files) do
        if string.GetExtensionFromFilename(fileName) == "lua" then
            local filePath = dir .. "/" .. fileName
            local realm = IncludeFile(filePath)
            
            -- Basic logging for all file loads (verbose logging handled in config)
            print(string.format("  [%s] Loaded: %s", realm, filePath))
        end
    end
    
    -- Load subdirectories if recursive
    if recursive then
        for _, folder in ipairs(folders) do
            LoadDirectory(dir .. "/" .. folder, true)
        end
    end
end

-- Load configuration files first
print("Loading configuration...")
LoadDirectory("config", false)

-- Load core systems
print("Loading core systems...")
LoadDirectory("core", false)

-- Load player systems
print("Loading player systems...")
LoadDirectory("player", false)

-- Load modules
print("Loading modules...")
LoadDirectory("modules", false)

-- Initialize server-side systems
if SERVER then
    -- Load whitelist data
    hook.Add("Initialize", "ProjectSovereign_Initialize", function()
        print("Initializing Project Sovereign gamemode...")
        
        -- Load whitelist
        GAMEMODE:LoadWhitelist()
        
        print("Project Sovereign initialized successfully!")
        print("======================================")
    end)
    
    -- Graceful shutdown
    hook.Add("ShutDown", "ProjectSovereign_Shutdown", function()
        print("Shutting down Project Sovereign...")
        
        -- Save all player data
        for _, ply in ipairs(player.GetAll()) do
            GAMEMODE:SavePlayerData(ply)
            GAMEMODE:SaveDataStore(ply)
        end
        
        -- Save whitelist
        GAMEMODE:SaveWhitelist()
        
        print("Project Sovereign shut down successfully.")
    end)
end

-- Initialize client-side systems
if CLIENT then
    hook.Add("Initialize", "ProjectSovereign_ClientInit", function()
        print("Project Sovereign client initialized")
    end)
end

-- Override sandbox hooks for gamemode-specific behavior
function GM:Initialize()
    print("GM:Initialize called")
end

-- Player initial spawn
function GM:PlayerInitialSpawn(ply)
    print(string.format("Player %s (%s) initial spawn", ply:Nick(), ply:SteamID()))
end

-- Player spawn
function GM:PlayerSpawn(ply)
    -- Default spawn behavior is handled by hooks in spawn.lua
    player_manager.SetPlayerClass(ply, "player_default")
end

-- Player death
function GM:PlayerDeath(victim, inflictor, attacker)
    -- Death behavior is handled by hooks in combat.lua and persistence.lua
end

-- Player say
function GM:PlayerSay(ply, text, teamChat)
    -- Commands are handled by commands.lua
    return text
end

-- Can player suicide
function GM:CanPlayerSuicide(ply)
    return true
end

-- Show help
function GM:ShowHelp(ply)
    -- Can be extended with a custom help menu
    ply:ChatPrint("=== Project Sovereign Help ===")
    ply:ChatPrint("Use /help to see available commands")
    ply:ChatPrint("Contact an admin for faction whitelist")
end

-- Show team
function GM:ShowTeam(ply)
    -- Can be extended with faction selection menu
    ply:ChatPrint("=== Your Faction Info ===")
    ply:ChatPrint("Faction: " .. (self:GetPlayerFaction(ply) or "None"))
    ply:ChatPrint("Rank: " .. (self:GetPlayerRank(ply) or "None"))
    ply:ChatPrint("Credits: " .. self:FormatCredits(self:GetPlayerCredits(ply)))
end

-- Show spawnmenu
function GM:ShowSpawnMenu(ply)
    -- Allow spawn menu for building (can be restricted later)
    return true
end

-- Player disconnect message
function GM:PlayerDisconnected(ply)
    self:NotifyAll(string.format("%s has left the server", ply:Nick()), NOTIFY_GENERIC)
end

-- Player connect message
function GM:PlayerConnect(name, ip)
    -- Don't show IP for privacy
    self:NotifyAll(string.format("%s is connecting...", name), NOTIFY_GENERIC)
end

print("Init.lua loaded successfully")
