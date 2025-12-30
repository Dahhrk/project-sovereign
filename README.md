# Project Sovereign

Project Sovereign is a Star Wars–inspired galactic gamemode built from the ground up with all-new systems never seen before. Control planets, command fleets, run empires, and shape the galaxy through war, politics, and strategy in a fully custom universe where only the elite rise.

## Development Status

### Phase 1 - Core Gamemode Architecture ✅ COMPLETE

The foundational roleplay systems have been implemented, including:

- **5 Playable Factions**: Republic, CIS, Jedi, Sith, and Civilian
- **Faction System**: Complete whitelist management and rank hierarchy
- **Persistence**: Auto-saving player data (credits, stats, playtime)
- **Economy**: Credit-based economy with transfers and transactions
- **Combat**: Statistics tracking and faction-based PvP rules
- **Commands**: 23 total commands (13 admin, 10 player)
- **Logging**: Comprehensive event logging system
- **Spawn System**: Faction-based spawning with spawn protection
- **Roleplay Enforcement**: Automatic faction loadouts and role assignments

**Lines of Code**: ~2,700  
**Total Files**: 14 new Lua files + 1 init.lua

## Quick Start

### Installation
1. Place the `gamemode` folder in your `garrysmod/gamemodes/project-sovereign/` directory
2. Set your server to run the gamemode: `sv_gamemode "project-sovereign"`
3. Start your server

### First-Time Setup
1. Join as admin/superadmin
2. Set faction spawn points: `/setspawn <faction>`
3. Add players to whitelists: `/addwhitelist <player> <faction> <rank>`
4. Players can check commands with `/help`

### Documentation
- **[Phase 1 Documentation](PHASE1_DOCUMENTATION.md)** - Complete system documentation
- **[Commands Reference](COMMANDS.md)** - All available commands and usage

## Features

### Faction System
- 5 unique factions with distinct ranks and roles
- Whitelist enforcement for role-playing integrity
- Faction-based team colors and player models
- Persistent faction assignments

### Economy System
- Starting balance: 5,000 credits
- Player-to-player credit transfers
- Admin credit management tools
- Economy transaction logging

### Combat & Statistics
- Kill/Death tracking
- Kill streak system with notifications
- Damage tracking (dealt/taken)
- Faction-based PvP rules
- Friendly fire protection

### Data Persistence
- Auto-save every 5 minutes
- Save on disconnect
- Stores: credits, playtime, kills/deaths, faction, rank
- Achievement system
- Player preferences

### Event Logging
- All admin actions logged
- Player actions logged
- Combat events logged
- Economy transactions logged
- Date-organized log files

## Commands

### For Players
- `/help` - View available commands
- `/balance` - Check your credits
- `/transfercredits <player> <amount>` - Send credits
- `/stats` - View your combat statistics
- `/achievements` - View your achievements

### For Admins
- `/addwhitelist <player> <faction> <rank>` - Whitelist player
- `/setfaction <player> <faction>` - Set player's faction
- `/givecredits <player> <amount>` - Give credits
- `/debugplayer <player>` - View player debug info
- `/respawn <player>` - Respawn a player

[See full command list](COMMANDS.md)

## Technical Details

### Directory Structure
```
gamemode/
├── init.lua                  # Main initialization
├── config/                   # Configuration files
│   ├── factions_config.lua
│   ├── loadouts_config.lua
│   └── server_config.lua
├── core/                     # Core systems
│   ├── factions.lua
│   ├── persistence.lua
│   ├── commands.lua
│   ├── roleplay_enforcement.lua
│   └── utils.lua
├── modules/                  # Optional modules
│   ├── economy.lua
│   ├── combat.lua
│   └── logger.lua
└── player/                   # Player systems
    ├── spawn.lua
    └── data_store.lua
```

### Data Storage
All gamemode data is stored in `garrysmod/data/project_sovereign/`:
- `whitelist.txt` - Faction whitelists
- `players/` - Individual player save files
- `datastore/` - Extended player data
- `logs/` - Event logs by date

## Configuration

Edit `gamemode/config/server_config.lua` to customize:
- Starting credits amount
- Auto-save interval
- Spawn protection duration
- Friendly fire settings
- PvP rules
- Logging options

## Roadmap

### Future Phases
- [ ] Phase 2: Advanced Economy (shops, jobs, economy balancing)
- [ ] Phase 3: Territory Control System
- [ ] Phase 4: Custom UI/HUD
- [ ] Phase 5: Mission/Quest System
- [ ] Phase 6: Fleet & Vehicle Systems
- [ ] Phase 7: Planetary Control & Warfare

## Contributing

This is a custom gamemode for Garry's Mod. Contributions and suggestions are welcome!

## License

See [LICENSE](LICENSE) for details.

---

**Version**: 1.0.0 - Phase 1  
**Author**: Dahhrk  
**Engine**: Garry's Mod (Source Engine)
