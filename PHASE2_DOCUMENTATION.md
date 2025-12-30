# Phase 2 Development - Implementation Documentation

## Overview
This document describes the Phase 2 implementation of Project Sovereign, extending the gamemode with advanced economy, missions, inventory, reputation, progression, and admin tools.

## New Systems Overview

### 1. Advanced Economy System

#### Player Marketplace
**File**: `gamemode/modules/marketplace.lua`

Players can buy and sell items through a persistent marketplace system.

**Features**:
- Create listings with item, price, and description
- Purchase items from other players
- Cancel active listings
- View all marketplace listings
- View personal listings

**Data Storage**: `data/project_sovereign/marketplace.txt`

#### Faction Budgets
**File**: `gamemode/modules/faction_budget.lua`

Shared faction resources with transaction tracking.

**Features**:
- Faction-wide credit pools (starting: 50,000 credits)
- Transaction history (last 100 transactions)
- Deposit/withdraw system
- Admin management tools

**Data Storage**: `data/project_sovereign/faction_budgets.txt`

#### Dynamic Taxes
**Extension**: `gamemode/modules/economy.lua`

Configurable tax system for economy balancing.

**Tax Types**:
- Transaction Tax: 5% (default)
- Purchase Tax: 10% (default)
- Toggle taxes on/off
- Admin-configurable rates

---

### 2. Mission and Event System

#### Dynamic Missions
**File**: `gamemode/modules/missions.lua`

Procedurally generated missions with multiple types and rewards.

**Mission Types**:
1. **Combat**: Defend bases, raid territories, eliminate targets
   - Rewards: 1,000 credits, 50 reputation (±variance)
2. **Economy**: Supply runs, resource delivery, trade
   - Rewards: 1,500 credits, 30 reputation (±variance)
3. **Exploration**: Scout zones, map territories, reconnaissance
   - Rewards: 800 credits, 40 reputation (±variance)

**Features**:
- Mission objectives with progress tracking
- Time limits (30 minutes default)
- Automatic expiration
- Faction-specific missions
- Difficulty ratings (1-5)

**Data Storage**: `data/project_sovereign/missions.txt`

#### Event Scheduler
**File**: `gamemode/modules/events.lua`

Time-based event system with recurring support.

**Features**:
- Schedule one-time events
- Schedule recurring events
- Automatic start/end based on time
- Event notifications to all players
- Manual event control (start/end/cancel)

**Data Storage**: `data/project_sovereign/events.txt`

---

### 3. Inventory and Crafting System

#### Player Inventories
**Files**: 
- `gamemode/framework/modules/inventory/sh_inventory.lua` (shared)
- `gamemode/framework/modules/inventory/sv_inventory.lua` (server)

Weight-based inventory system with item definitions.

**Features**:
- Weight limits (default: 100 kg)
- Stack limits per item
- Item categories (medical, ammunition, consumable, resource, currency)
- Item rarity system (common, uncommon, rare)
- Buy/sell values

**Default Items**:
1. Medkit (2 kg, stack: 5)
2. Ammo Pack (3 kg, stack: 10)
3. Ration Pack (1 kg, stack: 20)
4. Scrap Metal (5 kg, stack: 50)
5. Electronics (1 kg, stack: 20)
6. Weapon Parts (3 kg, stack: 10)
7. Credit Chip (0.1 kg, stack: 10)

**Data Storage**: `data/project_sovereign/inventories/<steamid>.txt`

#### Crafting System
**File**: `gamemode/modules/crafting.lua`

Resource combination mechanics with faction-specific recipes.

**Recipes**:
- General: Medkit, Ammo Pack
- Republic: Advanced Medkit
- CIS: Droid Components
- Jedi: Meditation Focus
- Sith: Dark Infusion

**Features**:
- Crafting time delays
- Material requirements
- Faction restrictions
- Rank requirements (optional)

---

### 4. Reputation and Progression System

#### Reputation System
**File**: `gamemode/modules/reputation.lua`

Per-faction reputation tracking integrated with missions.

**Reputation Levels** (with score ranges):
1. Despised: < -2500
2. Hated: -2500 to -1000
3. Hostile: -1000 to -500
4. Unfriendly: -500 to -100
5. Neutral: -100 to 100
6. Friendly: 100 to 500
7. Honored: 500 to 1000
8. Revered: 1000 to 2500
9. Exalted: 2500 to 5000
10. Legendary: 5000+

**Features**:
- Track reputation with all factions
- Gain reputation through missions
- Reputation affects access to content
- Admin management tools

**Data Storage**: `data/project_sovereign/reputation/<steamid>.txt`

#### Progression System
**File**: `gamemode/modules/progression.lua`

Skill trees with unlockable perks and abilities.

**Skill Trees**:

**Combat Skills**:
1. Improved Accuracy (5 levels, +5% per level)
2. Health Boost (5 levels, +20 HP per level)
3. Armor Enhancement (5 levels, +10 armor per level)
4. Weapon Mastery (3 levels, requires Accuracy 3)
5. Tactical Reload (3 levels, +15% reload speed per level)

**Economy Skills**:
1. Merchant (5 levels, +5% price discount per level)
2. Scavenger (5 levels, +10% resource bonus per level)
3. Investor (3 levels, +100 credits/hour passive income per level)
4. Trade Master (5 levels, -10% tax per level, requires Merchant 2)
5. Crafting Expert (3 levels, +20% speed, -10% materials per level)

**Features**:
- Skill point system
- Skill requirements and dependencies
- Skill reset functionality
- Earn points through promotions and achievements

**Data Storage**: `data/project_sovereign/skills/<steamid>.txt`

---

### 5. Expanded Admin and Debugging Tools

#### Auto-Moderation System
**File**: `gamemode/modules/automod.lua`

Automated rule enforcement with configurable punishments.

**Default Rules**:
1. **Spam** (Severity 2, Max 3 violations)
   - 1st: Warning
   - 2nd: Mute (5 minutes)
   - 3rd: Kick
   
2. **RDM** (Severity 4, Max 2 violations)
   - 1st: Warning
   - 2nd: Kick
   
3. **Combat Logging** (Severity 3, Max 2 violations)
   - 1st: Warning
   - 2nd: Temp Ban (1 hour)
   
4. **Faction Abuse** (Severity 3, Max 2 violations)
   - 1st: Warning
   - 2nd: Kick

**Features**:
- Offense tracking with history
- Automatic punishment escalation
- Admin override capabilities
- Offense clearing

**Data Storage**: `data/project_sovereign/offenses.txt`

#### Analytics System
**File**: `gamemode/modules/analytics.lua`

Real-time server statistics and metrics.

**Tracked Metrics**:
- Player count and activity
- Total server wealth
- Average wealth per player
- Top 10 richest players
- Faction distribution
- Faction power (total wealth per faction)
- Average playtime

**Features**:
- Auto-update every 5 minutes
- Wealth distribution analysis
- Faction power rankings

#### Enhanced Admin Commands

**Promote/Demote**:
- `/promote <player>` - Promote to next rank
- `/demote <player>` - Demote to previous rank
- Automatic skill point rewards on promotion

---

## Command Reference

### Economy Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/listitem` | `<item> <price> [description]` | Player | List item on marketplace |
| `/buyitem` | `<listingID>` | Player | Buy marketplace item |
| `/cancelitem` | `<listingID>` | Player | Cancel your listing |
| `/marketplace` | None | Player | View all listings |
| `/mylistings` | None | Player | View your listings |
| `/factionbalance` | None | Player | Check faction budget |
| `/factiondeposit` | `<amount>` | Player | Deposit to faction |
| `/factionwithdraw` | `<amount>` | Player | Withdraw from faction |
| `/factiontransactions` | None | Player | View faction transactions |
| `/setfactionbudget` | `<faction> <amount>` | Admin | Set faction budget |
| `/taxrates` | None | Player | View current tax rates |
| `/settaxrate` | `<type> <rate>` | Admin | Set tax rate |
| `/toggletaxes` | None | Admin | Enable/disable taxes |

### Mission Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/missions` | None | Player | View available missions |
| `/acceptmission` | `<missionID>` | Player | Accept a mission |
| `/checkmission` | None | Player | View active mission |
| `/abandonmission` | None | Player | Abandon active mission |
| `/generatemissions` | `[count]` | Admin | Generate new missions |

### Event Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/events` | None | Player | View active/upcoming events |
| `/scheduleevent` | `<type> <minutes> <duration> [desc]` | Admin | Schedule event |
| `/schedulerecurring` | `<type> <minutes> <duration> <interval> [desc]` | Admin | Schedule recurring event |
| `/cancelevent` | `<eventID>` | Admin | Cancel event |
| `/startevent` | `<eventID>` | Admin | Start event manually |
| `/endevent` | `<eventID>` | Admin | End event manually |

### Inventory Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/inventory` | None | Player | View your inventory |
| `/giveitem` | `<player> <item> [quantity]` | Player/Admin | Give item to player |
| `/additem` | `<player> <item> [quantity]` | Admin | Add item to inventory |
| `/removeitem` | `<player> <item> [quantity]` | Admin | Remove item from inventory |
| `/listitems` | None | Player | View all available items |

### Crafting Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/recipes` | `[tree]` | Player | View crafting recipes |
| `/craft` | `<recipeID>` | Player | Craft an item |
| `/recipeinfo` | `<recipeID>` | Player | View recipe details |

### Reputation Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/reputation` | None | Player | View all reputation |
| `/reputationcheck` | `[faction]` | Player | Check faction reputation |
| `/setreputation` | `<player> <faction> <amount>` | Admin | Set reputation |
| `/addreputation` | `<player> <faction> <amount>` | Admin | Add reputation |

### Progression Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/skills` | `[tree]` | Player | View skill tree |
| `/unlockskill` | `<tree> <skillID>` | Player | Unlock/level up skill |
| `/resetskills` | None | Player | Reset all skills |
| `/giveskillpoints` | `<player> <points>` | Admin | Give skill points |

### Admin Commands
| Command | Arguments | Permission | Description |
|---------|-----------|------------|-------------|
| `/promote` | `<player>` | Admin | Promote player |
| `/demote` | `<player>` | Admin | Demote player |
| `/warn` | `<player> <rule> [reason]` | Admin | Warn player |
| `/offenses` | `<player>` | Admin | View player offenses |
| `/clearoffenses` | `<player> [rule]` | Admin | Clear offenses |
| `/analytics` | None | Admin | View server analytics |
| `/factionpower` | None | Player | View faction power |
| `/wealthdistribution` | None | Admin | View wealth distribution |

---

## Integration Notes

### Phase 1 Integration
All Phase 2 systems integrate seamlessly with Phase 1:
- Marketplace uses Phase 1 economy and persistence
- Missions award reputation and credits from Phase 1
- Inventory integrates with Phase 1 player data
- Reputation ties to Phase 1 faction system
- Admin tools extend Phase 1 commands

### Data Persistence
All new systems save data to `data/project_sovereign/`:
- `marketplace.txt` - Marketplace listings
- `faction_budgets.txt` - Faction budgets
- `missions.txt` - Mission state
- `events.txt` - Scheduled events
- `inventories/<steamid>.txt` - Player inventories
- `reputation/<steamid>.txt` - Player reputation
- `skills/<steamid>.txt` - Player skills
- `offenses.txt` - Offense records

### Auto-Save
All systems auto-save every 5 minutes and on:
- Player disconnect
- Server shutdown
- Data modification

---

## Configuration

### Server Config
**File**: `gamemode/config/server_config.lua`

Key Phase 2 settings:
```lua
TransactionTaxRate = 0.05    -- 5% transfer tax
PurchaseTaxRate = 0.10       -- 10% purchase tax
StartingFactionBudget = 50000
DefaultInventoryWeight = 100
MissionExpirationTime = 1800 -- 30 minutes
AnalyticsUpdateInterval = 300
```

---

## Technical Details

### Total Phase 2 Code
- **New Modules**: 11 files
- **Extended Modules**: 2 files (economy.lua, commands.lua)
- **Lines of Code**: ~8,500+ new lines

### Performance
- Auto-save timers: 5-minute intervals
- Analytics updates: 5-minute intervals
- Event checks: 1-minute intervals
- Optimized for 128 players

---

## Testing Recommendations

### Economy Testing
1. Create marketplace listings
2. Buy/sell items
3. Test faction budgets (deposit/withdraw)
4. Verify tax calculations
5. Test transaction history

### Mission Testing
1. Generate missions
2. Accept and track missions
3. Complete objectives
4. Test expiration system
5. Verify rewards (credits, reputation)

### Inventory Testing
1. Add items to inventory
2. Test weight limits
3. Transfer items between players
4. Verify persistence

### Crafting Testing
1. Check available recipes
2. Craft items with materials
3. Test faction-specific recipes
4. Verify crafting time

### Reputation Testing
1. Complete missions for reputation
2. Check reputation levels
3. Test cross-faction reputation
4. Verify persistence

### Progression Testing
1. Unlock skills
2. Test skill requirements
3. Reset skills
4. Award skill points

### Admin Testing
1. Promote/demote players
2. Warn players
3. View analytics
4. Check faction power
5. Clear offenses

---

## Known Limitations

1. **No MySQL Support**: Currently SQLite (file-based) only
2. **Basic UI**: All interactions via chat commands
3. **Mission Objectives**: Currently placeholder, need implementation
4. **Crafting Effects**: Item use effects not implemented
5. **Skill Effects**: Passive bonuses need gameplay integration

---

## Future Enhancements

Potential Phase 3 additions:
1. Territory control system
2. Faction bases and structures
3. Custom UI/HUD for all systems
4. Advanced mission objectives
5. Player-vs-player combat rewards
6. Faction warfare mechanics

---

**Version**: 2.0.0 - Phase 2  
**Author**: Dahhrk  
**Last Updated**: 2025-12-30
