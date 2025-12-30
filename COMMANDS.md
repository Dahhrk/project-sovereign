# Project Sovereign - Complete Commands Reference

This document lists all commands for Phases 1-10 of Project Sovereign.

---

## Phase 1 & 2 Commands

### Player Commands
Commands that all players can use.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/help` | None | Display available commands |
| `/balance` | None | Check your credit balance |
| `/transfercredits` | `<player> <amount>` | Transfer credits to another player |
| `/stats` | `[player]` | View combat statistics (yours or specified player's if admin) |
| `/preferences` | None | View your preferences |
| `/achievements` | None | View your unlocked achievements |

### Admin Commands - Faction Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/addwhitelist` | `<player> <faction> <rank>` | Add a player to a faction whitelist with specified rank |
| `/removewhitelist` | `<player> <faction>` | Remove a player from a faction whitelist |
| `/setfaction` | `<player> <faction> [rank]` | Set a player's active faction (and optionally rank) |
| `/forcerank` | `<player> <rank>` | Force set a player's rank in their current faction |

### Admin Commands - Economy Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/givecredits` | `<player> <amount>` | Give credits to a player (creates money) |
| `/setcredits` | `<player> <amount>` | Set a player's credits to exact amount |
| `/checkbalance` | `<player>` | Check another player's credit balance |

### Admin Commands - Player Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/debugplayer` | `[player]` | Display detailed debug info about a player |
| `/respawn` | `[player]` | Respawn a player |
| `/setspawn` | `<faction>` | Set spawn location for a faction (stand at desired location) |
| `/resetstats` | `[player]` | Reset a player's combat statistics |

### Admin Commands - Logging & Debug
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/viewlogs` | `[count]` | View recent log entries (default: 10, max: 50) |
| `/clearlogs` | None | Clear the log queue |

---

## Phase 3 Commands - Territory & Base Upgrades

### Territory Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_territories` | None | View all territory status and ownership |
| `ps_captureinfo` | None | View active territory capture progress |

### Base Upgrade Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_baseinfo` | None | View your faction's base information and upgrades |
| `ps_upgrades` | None | View available base upgrades |
| `ps_purchaseupgrade` | `<upgradeId>` | Purchase base upgrade (admin/faction leader) |

---

## Phase 4 Commands - Galaxy & Dynamic Events

### Galaxy Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_galaxy` | None | View galaxy overview and statistics |
| `ps_sectors` | None | List all galaxy sectors |
| `ps_sectorinfo` | `<sectorId>` | View detailed sector information |

### Dynamic Events Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_activeevents` | None | View all active dynamic events |
| `ps_joinevent` | `<eventId>` | Join and participate in an event |
| `ps_completeevent` | `<eventId>` | Complete event and claim rewards |
| `ps_spawnevent` | `<eventType> <sectorId>` | Spawn dynamic event (admin) |

---

## Phase 5 Commands - Businesses & Diplomacy

### Business Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_businesses` | None | View available business types and costs |
| `ps_buybusiness` | `<businessType>` | Purchase a business |
| `ps_mybusinesses` | None | View your owned businesses |
| `ps_upgradebusiness` | `<businessId>` | Upgrade a business level |
| `ps_collectincome` | None | Collect pending offline income |

### Diplomacy Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_relations` | None | View your faction's diplomatic relations |
| `ps_proposealliance` | `<faction>` | Propose alliance with another faction (admin) |
| `ps_declarewar` | `<faction> [reason]` | Declare war on another faction (admin) |
| `ps_wars` | None | View all active wars and casualties |

---

## Phase 6 Commands - Player-Created Content

### Content Creation Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_createfaction` | `<name> [description]` | Create custom faction (50k cost) |
| `ps_createmission` | `<name> <description>` | Create custom mission (5k cost) |
| `ps_createevent` | `<name> <description>` | Create custom event (10k cost) |
| `ps_createbase` | `[name]` | Create custom base (25k cost) |
| `ps_mycontent` | None | View all your created content |
| `ps_approvecontent` | `<type> <id>` | Approve player content (admin) |

---

## Phase 7 Commands - NPC Systems

### NPC Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_npcfactions` | None | View all NPC factions and their stats |
| `ps_npcconflicts` | None | View active NPC faction conflicts |
| `ps_npcinfo` | `<factionId>` | View detailed NPC faction information |

---

## Phase 8 Commands - Seasonal Content

### Season Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_season` | None | View current season information |
| `ps_seasonprogress` | None | View your seasonal challenge progress |
| `ps_seasonleaderboard` | None | View seasonal leaderboard (top 10) |
| `ps_startseason` | None | Start new season (admin) |
| `ps_endseason` | None | End current season (admin) |

---

## Phase 9 Commands - Cosmetics

### Cosmetic Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_shop` | `[category]` | View cosmetic shop items |
| `ps_buycosmetic` | `<itemId>` | Purchase cosmetic item |
| `ps_equipcosmetic` | `<itemId> [slot]` | Equip cosmetic to slot |
| `ps_unequipcosmetic` | `<slot>` | Unequip cosmetic from slot |
| `ps_mycosmetics` | None | View owned and equipped cosmetics |
| `ps_customizefaction` | `<type> <data>` | Customize faction appearance (admin) |

---

## Phase 10 Commands - Ecosystem

### Ecosystem Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `ps_leaderboard` | `[type]` | View leaderboard (wealth/kills/reputation/businesses/territories) |
| `ps_webapi` | None | Export web API data (admin) |
| `ps_exportstructure` | None | Export gamemode structure for modding (admin) |
| `ps_createmodtemplate` | `<modName>` | Create modding template (admin) |
| `ps_transferserver` | `<serverId>` | Request cross-server transfer |
| `ps_serverstats` | None | View server statistics |

---

## Command Categories Summary

**Total Commands**: 100+

- **Phase 1-2**: ~60 commands
- **Phase 3**: 5 commands
- **Phase 4**: 7 commands
- **Phase 5**: 9 commands
- **Phase 6**: 6 commands
- **Phase 7**: 3 commands
- **Phase 8**: 5 commands
- **Phase 9**: 6 commands
- **Phase 10**: 6 commands

---

## Command Examples
```
/addwhitelist John Republic Private
/setfaction John Republic
/givecredits John 10000
```

### Promoting a player:
```
/forcerank John Corporal
```

### Checking a player's status:
```
/debugplayer John
/checkbalance John
/stats John
```

### Economy operations:
```
/transfercredits John 5000        (player command - transfers from your balance)
/givecredits John 5000            (admin command - creates money)
/setcredits John 100000           (admin command - sets exact amount)
```

### Faction setup:
```
/setspawn Republic                (stand at desired spawn point first)
/setspawn CIS
/setspawn Jedi
```

## Available Factions

### Republic
- **Ranks**: Private, Corporal, Sergeant, Lieutenant, Captain, Commander, General
- **Description**: The democratic governing body of the galaxy
- **Color**: Blue

### CIS (Confederacy of Independent Systems)
- **Ranks**: Droid, Battle Droid, Tactician, Commander, Leader
- **Description**: The separatist movement fighting for independence
- **Color**: Red

### Jedi
- **Ranks**: Youngling, Padawan, Knight, Master, Council Member
- **Description**: Peacekeepers and guardians of the Republic
- **Color**: Green

### Sith
- **Ranks**: Acolyte, Apprentice, Lord, Darth
- **Description**: Dark side users seeking power
- **Color**: Dark Red

### Civilian
- **Ranks**: Citizen, Worker, Merchant, Noble
- **Description**: Non-combatants and citizens
- **Color**: Gray

## Player Argument Formats

When a command requires `<player>`, you can specify the player using:
- **Full name**: `John Smith`
- **Partial name**: `John` (matches first player found)
- **SteamID**: `STEAM_0:1:12345678`
- **SteamID64**: `76561198012345678`

## Notes

- Commands are case-insensitive
- All commands must start with `/`
- Required arguments are shown in `<brackets>`
- Optional arguments are shown in `[square brackets]`
- Admin commands require the player to be an admin or superadmin
- Some commands will log to the server logs when executed
- Invalid arguments will show a usage message

## Starting Credits
- New players start with **5,000 credits**
- Maximum credits: **999,999,999**

## Default Settings
- **Spawn Protection**: 5 seconds (god mode + translucent)
- **Auto-save Interval**: 5 minutes
- **Friendly Fire**: Disabled
- **PvP**: Enabled (between hostile factions)
- **Whitelist Enforcement**: Enabled

---

# Phase 2 Commands

## Advanced Economy

### Marketplace Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/marketplace` | None | View all active marketplace listings |
| `/mylistings` | None | View your active listings |
| `/listitem` | `<item> <price> [description]` | List an item for sale on the marketplace |
| `/buyitem` | `<listingID>` | Purchase an item from the marketplace |
| `/cancelitem` | `<listingID>` | Cancel one of your marketplace listings |

### Faction Budget Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/factionbalance` | None | Check your faction's budget |
| `/factiondeposit` | `<amount>` | Deposit credits to your faction's budget |
| `/factionwithdraw` | `<amount>` | Withdraw credits from faction budget (requires permission) |
| `/factiontransactions` | None | View your faction's recent transactions |
| `/setfactionbudget` | `<faction> <amount>` | **[ADMIN]** Set a faction's budget |

### Tax Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/taxrates` | None | View current transaction and purchase tax rates |
| `/settaxrate` | `<type> <rate>` | **[ADMIN]** Set tax rate (type: transaction or purchase, rate: 0.0-1.0) |
| `/toggletaxes` | None | **[ADMIN]** Enable or disable economy taxes |

## Missions and Events

### Mission Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/missions` | None | View available missions |
| `/acceptmission` | `<missionID>` | Accept an available mission |
| `/checkmission` | None | View your active mission progress |
| `/abandonmission` | None | Abandon your current mission |
| `/generatemissions` | `[count]` | **[ADMIN]** Generate new random missions (default: 5, max: 20) |

### Event Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/events` | None | View active and upcoming events |
| `/scheduleevent` | `<type> <minutes_from_now> <duration_minutes> [description]` | **[ADMIN]** Schedule a one-time event |
| `/schedulerecurring` | `<type> <minutes_from_now> <duration_minutes> <interval_hours> [description]` | **[ADMIN]** Schedule a recurring event |
| `/cancelevent` | `<eventID>` | **[ADMIN]** Cancel a scheduled or active event |
| `/startevent` | `<eventID>` | **[ADMIN]** Manually start a scheduled event |
| `/endevent` | `<eventID>` | **[ADMIN]** Manually end an active event |

## Inventory and Crafting

### Inventory Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/inventory` | None | View your inventory and weight |
| `/giveitem` | `<player> <item> [quantity]` | Give an item to another player (admins can spawn items) |
| `/additem` | `<player> <item> [quantity]` | **[ADMIN]** Add an item to a player's inventory |
| `/removeitem` | `<player> <item> [quantity]` | **[ADMIN]** Remove an item from a player's inventory |
| `/listitems` | None | View all available items with details |

### Crafting Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/recipes` | `[tree]` | View available crafting recipes |
| `/craft` | `<recipeID>` | Craft an item using a recipe |
| `/recipeinfo` | `<recipeID>` | View detailed information about a recipe |

## Reputation and Progression

### Reputation Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/reputation` | None | View your reputation with all factions |
| `/reputationcheck` | `[faction]` | Check your reputation with a specific faction |
| `/setreputation` | `<player> <faction> <amount>` | **[ADMIN]** Set a player's reputation with a faction |
| `/addreputation` | `<player> <faction> <amount>` | **[ADMIN]** Add reputation to a player for a faction |

### Progression Commands
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/skills` | `[tree]` | View a skill tree (Combat or Economy) |
| `/unlockskill` | `<tree> <skillID>` | Unlock or level up a skill |
| `/resetskills` | None | Reset all your skills and refund skill points |
| `/giveskillpoints` | `<player> <points>` | **[ADMIN]** Give skill points to a player |

## Admin and Moderation

### Rank Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/promote` | `<player>` | **[ADMIN]** Promote a player to the next rank in their faction |
| `/demote` | `<player>` | **[ADMIN]** Demote a player to the previous rank in their faction |

### Auto-Moderation
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/warn` | `<player> <rule> [reason]` | **[ADMIN]** Warn a player for rule violation |
| `/offenses` | `<player>` | **[ADMIN]** View a player's recorded offenses |
| `/clearoffenses` | `<player> [rule]` | **[ADMIN]** Clear a player's offenses |

### Analytics
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/analytics` | None | **[ADMIN]** View comprehensive server analytics |
| `/factionpower` | None | View faction power rankings |
| `/wealthdistribution` | None | **[ADMIN]** View wealth distribution statistics |

---

**Phase 2 Total Commands**: 40+  
**Version**: 2.0.0 - Phase 2
