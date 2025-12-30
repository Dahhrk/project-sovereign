# Phase 1 Gamemode Development - Implementation Documentation

## Overview
This document describes the Phase 1 implementation of Project Sovereign, a Star Wars-themed roleplay gamemode for Garry's Mod.

## Architecture

### Directory Structure
```
gamemode/
├── init.lua                          # Main initialization file
├── config/                           # Configuration files
│   ├── factions_config.lua          # Faction and rank definitions
│   ├── loadouts_config.lua          # Loadout configurations per faction/rank
│   └── server_config.lua            # General server settings
├── core/                             # Core functionality
│   ├── utils.lua                    # Utility and helper functions
│   ├── factions.lua                 # Faction and whitelist management
│   ├── persistence.lua              # Player data save/load system
│   ├── commands.lua                 # Command handling system
│   └── roleplay_enforcement.lua     # Loadout and role enforcement
├── modules/                          # Modular systems
│   ├── economy.lua                  # Economy management
│   ├── combat.lua                   # Combat mechanics and tracking
│   └── logger.lua                   # Event logging system
└── player/                           # Player-specific systems
    ├── spawn.lua                    # Spawn handling and protection
    └── data_store.lua               # Extended player data storage
```

## Core Systems

### 1. Factions System (`core/factions.lua`)
Manages factions, ranks, and whitelist enforcement.

**Configured Factions:**
- Republic (7 ranks: Private to General)
- CIS (5 ranks: Droid to Leader)
- Jedi (5 ranks: Youngling to Council Member)
- Sith (4 ranks: Acolyte to Darth)
- Civilian (4 ranks: Citizen to Noble)

**Key Functions:**
- `GM:AddToWhitelist(ply, faction, rank)` - Add player to faction whitelist
- `GM:RemoveFromWhitelist(ply, faction)` - Remove player from whitelist
- `GM:SetPlayerFaction(ply, faction, rank)` - Set player's active faction
- `GM:IsWhitelisted(ply, faction)` - Check whitelist status
- `GM:GetPlayerFaction(ply)` - Get player's current faction
- `GM:GetPlayerRank(ply)` - Get player's current rank

**Data Persistence:**
- Whitelist data saved to: `data/project_sovereign/whitelist.txt`

### 2. Persistence System (`core/persistence.lua`)
Handles saving and loading player data.

**Tracked Data:**
- Credits (economy)
- Playtime
- Total kills/deaths
- First join timestamp
- Last seen timestamp
- Current faction and rank

**Key Functions:**
- `GM:SavePlayerData(ply)` - Save player data to disk
- `GM:LoadPlayerData(ply)` - Load player data from disk
- `GM:GetPlayerCredits(ply)` - Get player's credits
- `GM:SetPlayerCredits(ply, amount)` - Set player's credits
- `GM:AddPlayerCredits(ply, amount)` - Add credits to player
- `GM:RemovePlayerCredits(ply, amount)` - Remove credits from player
- `GM:CanAfford(ply, amount)` - Check if player can afford amount

**Auto-save Features:**
- Periodic auto-save every 5 minutes (configurable)
- Auto-save on player disconnect
- Auto-save on server shutdown

**Data Storage:**
- Player data saved to: `data/project_sovereign/players/<steamid>.txt`

### 3. Commands System (`core/commands.lua`)
Comprehensive command handling with permission checks.

**Admin Commands:**
- `/addwhitelist <player> <faction> <rank>` - Add player to faction whitelist
- `/removewhitelist <player> <faction>` - Remove player from whitelist
- `/setfaction <player> <faction> [rank]` - Set player's faction
- `/forcerank <player> <rank>` - Force set player's rank
- `/givecredits <player> <amount>` - Give credits to player
- `/setcredits <player> <amount>` - Set player's credits
- `/checkbalance <player>` - Check player's credit balance
- `/debugplayer [player]` - Display debug info
- `/setspawn <faction>` - Set spawn location for faction
- `/respawn [player]` - Respawn player
- `/resetstats [player]` - Reset combat statistics
- `/viewlogs [count]` - View recent log entries
- `/clearlogs` - Clear log queue

**Player Commands:**
- `/help` - Display available commands
- `/balance` - Check your credit balance
- `/transfercredits <player> <amount>` - Transfer credits
- `/stats [player]` - View combat statistics
- `/preferences` - View your preferences
- `/achievements` - View your achievements

### 4. Roleplay Enforcement (`core/roleplay_enforcement.lua`)
Enforces faction-based loadouts and behaviors.

**Features:**
- Automatic loadout application based on faction/rank
- Faction-based team colors
- Friendly fire control
- PvP validation between hostile factions
- Spawn protection system

**Key Functions:**
- `GM:ApplyLoadout(ply)` - Apply faction/rank loadout to player
- `GM:EnforceFactionRole(ply)` - Enforce faction role on player
- `GM:SetPlayerTeamColor(ply)` - Set player color based on faction
- `GM:AreSameFaction(ply1, ply2)` - Check if players are same faction
- `GM:AreFactionsHostile(faction1, faction2)` - Check faction hostility
- `GM:CanPvP(attacker, victim)` - Validate PvP action

**Faction Relationships:**
- Republic ↔ CIS, Sith (Hostile)
- Jedi ↔ Sith, CIS (Hostile)
- Civilians are neutral

### 5. Utility Functions (`core/utils.lua`)
Helper functions used throughout the gamemode.

**Key Functions:**
- `GM:Log(message, level)` - Log messages to console
- `GM:DebugLog(message)` - Debug logging (when enabled)
- `GM:ErrorLog(message)` - Error logging
- `GM:SanitizeString(str)` - Sanitize user input
- `GM:IsValidPlayer(ply)` - Check if player is valid
- `GM:FindPlayer(identifier)` - Find player by name or SteamID
- `GM:FormatCredits(amount)` - Format credits with separators
- `GM:FormatTime(seconds)` - Format time to human-readable
- `GM:HasPermission(ply, permission)` - Check admin permissions
- `GM:Notify(ply, message, type, duration)` - Send notification
- `GM:NotifyAll(message, type, duration)` - Notify all players

## Module Systems

### 1. Economy Module (`modules/economy.lua`)
Basic economy management system.

**Features:**
- Credit-based economy
- Purchase/sell transactions
- Player-to-player transfers
- Starting credits: 5,000 (configurable)
- Maximum credits: 999,999,999

**Functions:**
- `GM:PurchaseItem(ply, itemName, cost)` - Purchase item
- `GM:SellItem(ply, itemName, value)` - Sell item
- `GM:EconomyTransaction(sender, receiver, amount, reason)` - Generic transaction

### 2. Combat Module (`modules/combat.lua`)
Combat mechanics and statistics tracking.

**Tracked Statistics:**
- Kills and deaths
- K/D ratio
- Kill streaks
- Damage dealt/taken
- Best kill streak

**Features:**
- Kill streak notifications (at 5+ kills)
- Faction combat tracking
- Combat statistics per player

### 3. Logger Module (`modules/logger.lua`)
Comprehensive event logging system.

**Log Categories:**
- ADMIN - Admin actions
- PLAYER - Player actions
- COMBAT - Combat events
- ECONOMY - Economic transactions
- FACTION - Faction changes

**Features:**
- Automatic logging of key events
- Log queue management (max 1,000 entries)
- Periodic log file saves
- Log file organization by date
- Configurable verbose logging

**Data Storage:**
- Logs saved to: `data/project_sovereign/logs/log_<date>.txt`

## Player Systems

### 1. Spawn System (`player/spawn.lua`)
Handles player spawning and spawn protection.

**Features:**
- Faction-based spawn locations
- 5-second spawn protection (configurable)
- Faction-specific player models
- Custom spawn point management

**Default Spawn Locations:**
- Republic: (0, 0, 100)
- CIS: (500, 0, 100)
- Jedi: (-500, 0, 100)
- Sith: (0, 500, 100)
- Civilian: (0, -500, 100)

### 2. Data Store System (`player/data_store.lua`)
Extended player data storage beyond basic persistence.

**Stored Data:**
- Player preferences (UI settings, etc.)
- Achievements
- Custom data fields

**Features:**
- Achievement system
- Preference management
- Auto-save every 10 minutes
- Separate storage from main player data

**Data Storage:**
- Data store saved to: `data/project_sovereign/datastore/<steamid>.txt`

## Configuration

### Server Configuration (`config/server_config.lua`)
Key settings:
- `StartingCredits`: 5,000
- `AutoSaveInterval`: 300 seconds
- `SpawnProtectionTime`: 5 seconds
- `EnforceWhitelist`: true
- `FriendlyFire`: false
- `PvPEnabled`: true
- `EnableLogging`: true

### Factions Configuration (`config/factions_config.lua`)
Defines all factions with:
- Display name
- Description
- Team color
- Rank hierarchy

### Loadouts Configuration (`config/loadouts_config.lua`)
Defines per-faction, per-rank:
- Weapon loadouts
- Health values
- Armor values

## Hooks and Integration

### Server Initialization
1. Load configuration files
2. Load core systems
3. Load player systems
4. Load modules
5. Initialize whitelist data
6. Start auto-save timers

### Player Join Flow
1. Player connects
2. Load whitelist data for player
3. Initialize faction/rank (from saved data or defaults)
4. Load player data from disk
5. Load extended data store
6. Apply faction and loadout

### Player Disconnect Flow
1. Update playtime
2. Save player data
3. Save data store
4. Log disconnection

## Testing Recommendations

### Manual Testing Checklist
1. **Faction System**
   - [ ] Add player to whitelist
   - [ ] Remove player from whitelist
   - [ ] Set player faction
   - [ ] Verify faction persistence on rejoin

2. **Economy System**
   - [ ] Transfer credits between players
   - [ ] Check balance
   - [ ] Admin give/set credits
   - [ ] Verify credit persistence

3. **Combat System**
   - [ ] Test PvP between hostile factions
   - [ ] Test friendly fire prevention
   - [ ] View combat statistics
   - [ ] Test kill streak notifications

4. **Spawn System**
   - [ ] Verify spawn protection
   - [ ] Test faction-based spawns
   - [ ] Set custom spawn locations

5. **Data Persistence**
   - [ ] Join server and set faction
   - [ ] Disconnect and rejoin
   - [ ] Verify data persisted correctly

## Known Limitations

1. **No MySQL Support**: Currently only SQLite (file-based) storage
2. **Placeholder Weapons**: Using default GMod weapons (physgun, tool gun)
3. **Basic Models**: Using default GMod player models as placeholders
4. **No UI**: All interactions via chat commands
5. **Fixed Spawn Locations**: Spawn locations are hardcoded vectors

## Future Enhancements (Post-Phase 1)

1. Custom weapon system integration
2. MySQL database support
3. Custom UI/HUD systems
4. Advanced economy (shops, jobs)
5. Custom player models per faction
6. Territory control system
7. Mission/quest system
8. Rank progression system

## Troubleshooting

### Common Issues

**Issue**: "Invalid faction" error
- **Solution**: Check faction name spelling in `config/factions_config.lua`

**Issue**: Player data not saving
- **Solution**: Check file permissions in `garrysmod/data/project_sovereign/`

**Issue**: Commands not working
- **Solution**: Ensure commands start with `/` and check admin permissions

**Issue**: Loadout not applying
- **Solution**: Verify faction and rank are valid in respective config files

## Support

For issues or questions about this implementation:
1. Check this documentation
2. Review configuration files
3. Check server console for error messages
4. Review log files in `data/project_sovereign/logs/`

---

**Version**: 1.0.0 - Phase 1  
**Author**: Dahhrk  
**Last Updated**: 2025-12-30
