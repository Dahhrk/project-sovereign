-- Faction System: Core management for factions and ranks

FACTIONS = {
    Republic = {
        name = "Republic",
        ranks = { "Trooper", "Sergeant", "Commander" }
    },
    Separatists = {
        name = "Separatists",
        ranks = { "B1 Droid", "Tactical Droid", "General" }
    },
    Neutral = {
        name = "Neutral",
        ranks = { "Civilian" }
    }
}

-- Assign a player to a faction
function AssignFaction(player, factionName)
    if FACTIONS[factionName] then
        player.faction = factionName
        player.rank = FACTIONS[factionName].ranks[1] -- Assign default rank
        print(player:Nick() .. " has been assigned to faction " .. factionName)
    else
        print("Faction " .. factionName .. " does not exist!")
    end
end

-- Get the faction of a player
function GetFaction(player)
    return player.faction or "Neutral"
end

-- Get the rank of a player within their faction
function GetFactionRank(player)
    return player.rank or "None"
end

-- Set the rank of a player within their faction
function SetFactionRank(player, rank)
    local faction = FACTIONS[player.faction]
    if faction and table.HasValue(faction.ranks, rank) then
        player.rank = rank
        print(player:Nick() .. "'s rank has been updated to " .. rank)
    else
        print("Invalid rank " .. rank .. " for faction " .. (player.faction or "None"))
    end
end