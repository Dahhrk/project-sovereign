-- Player Persistence System: Handles saving/loading player-specific data

PLAYER_DATA = {}

-- Save player data to memory (placeholder for database/file storage)
function SavePlayerData(player)
    PLAYER_DATA[player:SteamID()] = {
        faction = player.faction,
        rank = player.rank,
        credits = player.credits or 0
    }
    print("Player data saved for: " .. player:Nick())
end

-- Load player data from memory (or assign defaults if none exists)
function LoadPlayerData(player)
    local data = PLAYER_DATA[player:SteamID()]
    if data then
        player.faction = data.faction
        player.rank = data.rank
        player.credits = data.credits
        print("Player data loaded for: " .. player:Nick())
    else
        -- Assign default data for new players
        player.faction = "Neutral"
        player.rank = "Civilian"
        player.credits = 0
        print("New player initialized: " .. player:Nick())
    end
end

-- Hook into player spawn for loading data
hook.Add("PlayerInitialSpawn", "LoadPlayerData", LoadPlayerData)

-- Hook into player disconnect for saving data
hook.Add("PlayerDisconnected", "SavePlayerData", SavePlayerData)