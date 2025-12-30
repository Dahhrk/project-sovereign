--[[
    Factions Configuration
    Defines all valid factions and their ranks for the gamemode
]]--

GM.Factions = GM.Factions or {}

GM.Factions = {
    ["Republic"] = {
        name = "Galactic Republic",
        description = "The democratic governing body of the galaxy",
        color = Color(0, 100, 200),
        ranks = {
            "Private",
            "Corporal",
            "Sergeant",
            "Lieutenant",
            "Captain",
            "Commander",
            "General"
        }
    },
    ["CIS"] = {
        name = "Confederacy of Independent Systems",
        description = "The separatist movement fighting for independence",
        color = Color(200, 50, 50),
        ranks = {
            "Droid",
            "Battle Droid",
            "Tactician",
            "Commander",
            "Leader"
        }
    },
    ["Jedi"] = {
        name = "Jedi Order",
        description = "Peacekeepers and guardians of the Republic",
        color = Color(0, 200, 100),
        ranks = {
            "Youngling",
            "Padawan",
            "Knight",
            "Master",
            "Council Member"
        }
    },
    ["Sith"] = {
        name = "Sith Order",
        description = "Dark side users seeking power",
        color = Color(150, 0, 0),
        ranks = {
            "Acolyte",
            "Apprentice",
            "Lord",
            "Darth"
        }
    },
    ["Civilian"] = {
        name = "Civilian",
        description = "Non-combatants and citizens",
        color = Color(150, 150, 150),
        ranks = {
            "Citizen",
            "Worker",
            "Merchant",
            "Noble"
        }
    }
}

-- Helper function to validate faction existence
function GM:IsValidFaction(factionName)
    return self.Factions[factionName] ~= nil
end

-- Helper function to validate rank for a faction
function GM:IsValidRank(factionName, rankName)
    if not self:IsValidFaction(factionName) then
        return false
    end
    
    for _, rank in ipairs(self.Factions[factionName].ranks) do
        if rank == rankName then
            return true
        end
    end
    
    return false
end

-- Get default rank for a faction
function GM:GetDefaultRank(factionName)
    if not self:IsValidFaction(factionName) then
        return nil
    end
    
    return self.Factions[factionName].ranks[1]
end
