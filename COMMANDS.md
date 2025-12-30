# Project Sovereign - Phase 1 Commands Reference

## Player Commands
Commands that all players can use.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/help` | None | Display available commands |
| `/balance` | None | Check your credit balance |
| `/transfercredits` | `<player> <amount>` | Transfer credits to another player |
| `/stats` | `[player]` | View combat statistics (yours or specified player's if admin) |
| `/preferences` | None | View your preferences |
| `/achievements` | None | View your unlocked achievements |

## Admin Commands
Commands that require admin permissions.

### Faction Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/addwhitelist` | `<player> <faction> <rank>` | Add a player to a faction whitelist with specified rank |
| `/removewhitelist` | `<player> <faction>` | Remove a player from a faction whitelist |
| `/setfaction` | `<player> <faction> [rank]` | Set a player's active faction (and optionally rank) |
| `/forcerank` | `<player> <rank>` | Force set a player's rank in their current faction |

### Economy Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/givecredits` | `<player> <amount>` | Give credits to a player (creates money) |
| `/setcredits` | `<player> <amount>` | Set a player's credits to exact amount |
| `/checkbalance` | `<player>` | Check another player's credit balance |

### Player Management
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/debugplayer` | `[player]` | Display detailed debug info about a player |
| `/respawn` | `[player]` | Respawn a player |
| `/setspawn` | `<faction>` | Set spawn location for a faction (stand at desired location) |
| `/resetstats` | `[player]` | Reset a player's combat statistics |

### Logging & Debug
| Command | Arguments | Description |
|---------|-----------|-------------|
| `/viewlogs` | `[count]` | View recent log entries (default: 10, max: 50) |
| `/clearlogs` | None | Clear the log queue |

## Command Examples

### Setting up a new player:
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
