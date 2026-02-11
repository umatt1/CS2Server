# CS2 Server Enhancement Guide

This document provides detailed instructions for customizing your CS2 server with plugins, custom maps, and advanced configurations.

## Table of Contents

1. [Workshop Maps](#workshop-maps)
2. [Server Plugins](#server-plugins)
3. [In-Game Commands](#in-game-commands)
4. [Custom Game Modes](#custom-game-modes)
5. [Advanced CVARs](#advanced-cvars)

---

## Workshop Maps

### Adding a Workshop Collection

1. Create a collection on Steam Workshop: https://steamcommunity.com/workshop/browse/?appid=730

2. Get your collection ID from the URL:
   ```
   https://steamcommunity.com/sharedfiles/filedetails/?id=YOUR_COLLECTION_ID
   ```

3. Update `terraform.tfvars`:
   ```hcl
   workshop_collection_id = "YOUR_COLLECTION_ID"
   workshop_start_map_id  = "MAP_ID_FROM_COLLECTION"
   ```

4. Apply changes:
   ```bash
   terraform apply
   ```

### Popular Workshop Collections

- **Competitive Maps**: Active Duty + Reserve maps
- **Aim Training**: aim_botz, aim_redline, training_aim_csgo2
- **Fun Maps**: surf_, bhop_, kz_, awp_, gg_ maps
- **Practice**: execute maps, nade lineup maps, prefire maps

### Changing Maps via RCON

```
rcon_password your_password
rcon changelevel de_mirage
rcon ds_workshop_changelevel aim_botz
```

---

## Server Plugins

### Option 1: CounterStrikeSharp (Recommended)

**What it is**: Modern C# plugin framework for CS2

**Installation**:
1. SSH to server:
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw public_ip)
   ```

2. Stop CS2 service:
   ```bash
   sudo systemctl stop cs2.service
   ```

3. Download and install CounterStrikeSharp:
   ```bash
   cd /opt/cs2-server/game/csgo
   wget https://github.com/roflmuffin/CounterStrikeSharp/releases/latest/download/counterstrikesharp-build-linux.zip
   unzip counterstrikesharp-build-linux.zip
   ```

4. Start service:
   ```bash
   sudo systemctl start cs2.service
   ```

**Popular Plugins**:
- **Admin System**: Role-based permissions
- **Weapon Restrictor**: Limit AWPs, auto-snipers
- **RTVs**: Rock the Vote for map changes
- **Practice Mode**: Grenade trajectories, noclip
- **Retake**: Post-plant practice scenarios

### Option 2: Metamod:Source + SourceMod

**What it is**: Classic plugin loader and scripting framework

**Installation**: Similar process, download from https://www.sourcemm.net/

**Popular Plugins**:
- SourceMod Admin Suite
- Map management plugins
- Player statistics
- Anti-cheat extensions

### Using CS2_CFG_URL (Automated)

Package your plugins in a tar.gz and host it:

```hcl
# In user_data.sh.tftpl, add to Docker command:
-e CS2_CFG_URL="https://yourdomain.com/cs2-plugins.tar.gz"
```

The Docker container will automatically download and extract on startup.

---

## In-Game Commands

### RCON Access

Connect via console:
```
rcon_password your_password
rcon <command>
```

Or use external tools:
- **HLSW**: Desktop RCON client
- **RCONcmd**: Command-line tool
- **Web RCON**: Browser-based panels

### Essential Admin Commands

**Server Management**:
```
rcon changelevel de_mirage          # Change map
rcon mp_restartgame 1               # Restart match
rcon exec gamemode_deathmatch       # Load different mode config
rcon sv_password mypass             # Set/change server password
```

**Player Management**:
```
rcon status                         # List all players
rcon kick "PlayerName"              # Kick player
rcon kickid <userid>                # Kick by ID
rcon banid <minutes> <userid>       # Temporary ban
rcon sm_ban <name> <time> <reason>  # SourceMod ban
```

**Match Control**:
```
rcon mp_warmup_end                  # End warmup
rcon mp_warmuptime 60               # Set warmup duration
rcon mp_pause_match                 # Pause competitive match
rcon mp_unpause_match               # Unpause match
rcon mp_overtime_enable 1           # Enable overtime
```

**Practice Commands**:
```
rcon sv_cheats 1                    # Enable cheats for practice
rcon sv_infinite_ammo 1             # Infinite ammo
rcon sv_grenade_trajectory 1        # Show grenade paths
rcon bot_add_ct                     # Add bot to CT
rcon bot_kick                       # Remove all bots
rcon mp_buy_anywhere 1              # Buy from anywhere
rcon mp_buytime 99999               # Unlimited buy time
```

### Creating Custom Command Aliases

Edit `templates/autoexec.cfg.tftpl`:
```cfg
// Quick restart
alias restart "mp_restartgame 1"

// Fast forward (end rounds quickly)
alias ff "mp_roundtime 0.1; mp_freezetime 0; mp_round_restart_delay 0"

// Reset after ff
alias reset "mp_roundtime 1.92; mp_freezetime 15; mp_round_restart_delay 7"

// Practice mode toggle
alias prac "sv_cheats 1; sv_infinite_ammo 1; mp_buy_anywhere 1; sv_grenade_trajectory 1"
alias unprac "sv_cheats 0; sv_infinite_ammo 0; mp_buy_anywhere 0; sv_grenade_trajectory 0"
```

Then use: `rcon restart`, `rcon ff`, `rcon prac`, etc.

---

## Custom Game Modes

### Creating a New Game Mode

1. Create new template file:
   ```bash
   touch templates/gamemode_retake.cfg.tftpl
   ```

2. Define the mode:
   ```cfg
   // Retake Mode Configuration
   mp_roundtime 1.5
   mp_roundtime_defuse 1.5
   mp_freezetime 0
   mp_buytime 0
   mp_buy_anywhere 1
   mp_startmoney 16000
   sv_infinite_ammo 2              // Infinite reserve ammo
   mp_respawn_on_death_ct 0
   mp_respawn_on_death_t 0
   mp_halftime 0
   mp_maxrounds 20
   
   // Plugin-based retake mode logic would go here
   // (requires RetakePlugin via CounterStrikeSharp)
   ```

3. Add to Terraform:
   ```hcl
   # In locals block in main.tf
   game_mode_config = {
     competitive = "gamemode_competitive"
     casual      = "gamemode_casual"
     deathmatch  = "gamemode_deathmatch"
     practice    = "practice"
     retake      = "gamemode_retake"  # NEW
   }
   ```

4. Update `variables.tf` validation:
   ```hcl
   validation {
     condition     = contains(["competitive", "casual", "deathmatch", "practice", "retake"], var.game_mode)
     error_message = "Game mode must be one of: competitive, casual, deathmatch, practice, retake"
   }
   ```

### Popular Custom Modes

**Executes**:
- Team-based execute practice
- Respawn on death
- Quick rounds
- Specific spawn locations

**1v1 Arena**:
- Multiple 1v1 arenas on one server
- Round robin matchmaking
- ELO ranking system
- Requires plugin framework

**Gun Game**:
- Progressive weapon mode
- First to knife wins
- Instant respawn

**Surf/KZ/Bhop**:
- Movement-based modes
- Timer system
- Checkpoint saving
- Leaderboards

---

## Advanced CVARs

### Using server_cvars Map

In `terraform.tfvars`:
```hcl
server_cvars = {
  # Economy
  "mp_startmoney"             = "16000"
  "mp_maxmoney"               = "65535"
  "cash_team_win_by_defusing_bomb" = "3500"
  
  # Round timers
  "mp_roundtime"              = "1.92"     # Minutes (1.92 = 1:55)
  "mp_roundtime_defuse"       = "1.92"
  "mp_freezetime"             = "15"
  "mp_round_restart_delay"    = "7"
  
  # Tactical
  "mp_buytime"                = "45"
  "mp_buy_anywhere"           = "0"
  "sv_alltalk"                = "0"
  "mp_teammates_are_enemies"  = "0"
  
  # Practice mode CVARs
  "sv_infinite_ammo"          = "0"        # 0=off, 1=no reload, 2=infinite reserve
  "sv_grenade_trajectory"     = "0"        # Show grenade path
  "sv_showimpacts"            = "0"        # Show bullet impacts
  "sv_showimpacts_time"       = "10"
  
  # Server performance
  "sv_maxrate"                = "0"        # 0 = unlimited
  "sv_minrate"                = "128000"
  "sv_mincmdrate"             = "64"
  "sv_maxcmdrate"             = "128"
  "sv_client_min_interp_ratio" = "1"
  "sv_client_max_interp_ratio" = "2"
}
```

### Game Mode Specific CVARs

**Competitive** (5v5 MR12):
- `mp_maxrounds 24`
- `mp_overtime_enable 1`
- `mp_overtime_maxrounds 6`

**Casual**:
- `mp_respawn_on_death_ct 0`
- `mp_respawn_on_death_t 0`
- `mp_friendlyfire 0`

**Deathmatch**:
- `mp_respawn_on_death_t 1`
- `mp_respawn_on_death_ct 1`
- `mp_dm_bonus_length_max 60`

**Practice**:
- `sv_cheats 1`
- `mp_limitteams 0`
- `mp_autoteambalance 0`
- `mp_buy_anywhere 1`
- `mp_buytime 99999`

### Applying CVARs Live

Via RCON:
```
rcon sv_grenade_trajectory 1
rcon mp_roundtime 2.5
rcon mp_restartgame 1
```

Or exec a config:
```
rcon exec practice.cfg
```

---

## Useful Resources

- **CS2 Server Documentation**: https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers
- **CounterStrikeSharp**: https://github.com/roflmuffin/CounterStrikeSharp
- **Metamod:Source**: https://www.sourcemm.net/
- **SourceMod**: https://www.sourcemod.net/
- **Workshop**: https://steamcommunity.com/app/730/workshop/
- **CVAR List**: Community-maintained lists on Reddit/Discord

## Getting Help

- **Server not starting**: Check logs with `sudo journalctl -u cs2.service -n 100`
- **Plugins not loading**: Verify file permissions and paths
- **CVARs not working**: Some require `mp_restartgame 1` or server restart
- **Workshop maps not downloading**: Players need good connection; maps auto-download on join
