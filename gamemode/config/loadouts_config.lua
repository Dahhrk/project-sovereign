--[[
    Loadouts Configuration
    Defines loadout associations per faction and rank
]]--

GM.Loadouts = GM.Loadouts or {}

GM.Loadouts = {
    ["Republic"] = {
        ["Private"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 50,
            health = 100
        },
        ["Corporal"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 60,
            health = 100
        },
        ["Sergeant"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 70,
            health = 100
        },
        ["Lieutenant"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 80,
            health = 110
        },
        ["Captain"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 90,
            health = 120
        },
        ["Commander"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 100,
            health = 130
        },
        ["General"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 100,
            health = 150
        }
    },
    ["CIS"] = {
        ["Droid"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 40,
            health = 80
        },
        ["Battle Droid"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 50,
            health = 90
        },
        ["Tactician"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 70,
            health = 100
        },
        ["Commander"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 90,
            health = 120
        },
        ["Leader"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 100,
            health = 150
        }
    },
    ["Jedi"] = {
        ["Youngling"] = {
            weapons = {
                "weapon_physgun"
            },
            armor = 30,
            health = 100
        },
        ["Padawan"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 50,
            health = 120
        },
        ["Knight"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 70,
            health = 140
        },
        ["Master"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 90,
            health = 160
        },
        ["Council Member"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 100,
            health = 200
        }
    },
    ["Sith"] = {
        ["Acolyte"] = {
            weapons = {
                "weapon_physgun"
            },
            armor = 40,
            health = 110
        },
        ["Apprentice"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 60,
            health = 130
        },
        ["Lord"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 80,
            health = 150
        },
        ["Darth"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 100,
            health = 200
        }
    },
    ["Civilian"] = {
        ["Citizen"] = {
            weapons = {},
            armor = 0,
            health = 100
        },
        ["Worker"] = {
            weapons = {
                "weapon_physgun"
            },
            armor = 10,
            health = 100
        },
        ["Merchant"] = {
            weapons = {
                "weapon_physgun"
            },
            armor = 20,
            health = 100
        },
        ["Noble"] = {
            weapons = {
                "weapon_physgun",
                "gmod_tool"
            },
            armor = 30,
            health = 120
        }
    }
}

-- Helper function to get loadout for a faction/rank combination
function GM:GetLoadout(factionName, rankName)
    if not self.Loadouts[factionName] then
        return nil
    end
    
    return self.Loadouts[factionName][rankName]
end
