# CS2 Server Terraform Project - Current State

**Date:** February 11, 2026  
**Branch:** `copilot/add-cs2-server-terraform`  
**Status:** 🚀 **PHASE 1 IN PROGRESS** - Plugin framework integrated, ready for deployment

## Project Overview

Fully-configured Counter-Strike 2 dedicated server on AWS using Terraform with **automated plugin installation**. Infrastructure code now includes CounterStrikeSharp framework and support for 3 training modes (retakes, practice-plus, deathmatch-custom).

**Server Status:** Infrastructure tore down - ready for incremental deployment with plugins

## What's Working ✅

### Infrastructure (Fully Functional)
- **Terraform Configuration**: Complete IaC setup for AWS deployment
  - versions.tf, providers.tf, variables.tf, main.tf, outputs.tf
  - Validates successfully
  - Deploys without errors
  
- **AWS Resources**: All infrastructure deploys correctly
  - EC2 instance: t3.medium running Ubuntu 22.04 LTS in us-east-2
  - Networking: Default VPC with custom subnet (172.31.1.0/24)
  - Security groups: SSH (22/tcp), CS2 (27015/udp), GOTV (27020/udp)
  - SSH access: Key-based authentication with ~/.ssh/id_rsa
  
- **Docker Setup**: Container platform fully operational
  - Docker CE 29.2.1 installed via official repository
  - systemd service (cs2.service) configured and starts successfully
  - Using community image: joedwards32/cs2:latest
  - Container runs but fails during CS2 download phase

### Configuration System (Complete but Untested)
- **Modular Template System**: 6 game mode configs ready
  - `templates/server.cfg.tftpl` - Base server config (40+ CVARs)
  - `templates/autoexec.cfg.tftpl` - Startup commands
  - `templates/gamemode_competitive.cfg.tftpl` - 5v5 MR12
  - `templates/gamemode_casual.cfg.tftpl` - Casual mode
  - `templates/gamemode_deathmatch.cfg.tftpl` - DM with respawns
  - `templates/practice.cfg.tftpl` - Practice/grenade mode

- **Variables**: Comprehensive configuration options
  - Tickrate: 64 or 128 (validated)
  - Game modes: competitive/casual/deathmatch/practice (validated)
  - **Plugin modes**: vanilla/retakes/practice-plus/deathmatch-custom (NEW ✨)
  - Workshop: collection_id and start_map_id support
  - Custom CVARs: Map of additional server settings
  - Passwords: Server password, RCON password (sensitive)
  - GSLT: Game Server Login Token (sensitive)
  - Spot instance: Cost optimization with 70% savings

### Plugin System (NEW - Phase 1) ✨
- **CounterStrikeSharp Framework**: Automated installation during server bootstrap
  - Latest version fetched from GitHub releases
  - Installed to `/opt/cs2-server/game/csgo/addons/counterstrikesharp`
  
- **Supported Plugin Modes**:
  - `vanilla`: No plugins (base CS2 server)
  - `retakes`: CS2-Retakes plugin for post-plant practice
  - `practice-plus`: Enhanced practice with .noclip, .god, .bot commands
  - `deathmatch-custom`: Custom DM with weapon menu and instant respawn
  - `executes`: Placeholder (community plugin TBD)
  - `prefire`: Placeholder (community plugin TBD)

- **Automated Plugin Installation**: Plugins download and install during user_data bootstrap
  - Version detection via GitHub API
  - Automatic unzip and configuration
  - No manual SSH required

- **Files Generated**: All configs written to `/opt/cs2-server/game/csgo/cfg/`
  - Mounted as Docker volume
  - NevProblem (SOLVED) ✅

### Error 0x202: The Authentication Red Herring

**What we thought**: Error 0x202 meant "authentication failed" - spent hours researching Steam credentials, GSLT tokens, anonymous login issues.

**What it actually meant**: **"Not enough disk space"** (discovered via LinuxGSM source code)

### The Real Issue

CS2 dedicated server requires:
- **~35GB** for game files
- **~15-20GB** for temporary extraction during install
- **Total: 50-60GB minimum**

Our EC2 instance had the **default 8GB root volume** - nowhere near enough space.

### The Solution

Added proper disk allocation to `main.tf`:
```hcl
root_block_device {
  volume_size = 80  # GB - CS2 needs ~35GB + extraction space
  volume_type = "gp3"
  encrypted   = true
}
```

**Result**: CS2 immediately started downloading successfully (state 0x61) with anonymous SteamCMD - no authentication needed!
- Learning opportunity lost
- Can't customize beyond panel options

## File Inventory

### Terraform Files
- `versions.tf` - Version constraints
- `providers.tf` - AWS provider config
- `variables.tf` - 20+ input variables
- `main.tf` - AWS resources (VPC, subnet, SG, EC2)
- `outputs.tf` - Connection info (IP, connect string)
- `user_data.sh.tftpl` - EC2 bootstrap script (Docker-based)
- `terraform.tfvars` - Actual values (GITIGNORED - contains GSLT)
- `terraform.tfvars.example` - Template with comments
- `.gitignore` - Protects state files and tfvars

### Config Templates
- `templates/server.cfg.tftpl` - 40+ CVARs for server behavior
- `templates/autoexec.cfg.tftpl` - Auto-exec commands
- `templates/gamemode_competitive.cfg.tftpl` - 5v5 competitive
- `templates/gamemode_casual.cfg.tftpl` - Casual rules
- `templates/gamemode_deathmatch.cfg.tftpl` - DM mode
- `templates/practice.cfg.tftpl` - Practice/nade mode

### Documentation
- `README.md` - Comprehensive setup guide (180+ lines)
- `LICENSE` - Project license
- `PROJECT_STATE.md` - This file

## Current Configuration Values

From `terraform.tfvars` (sensitive values redacted for this doc):
```hcl
project_name = "cs2-server"
aws_region   = "us-east-2"
instance_type = "t3.medium"
public_key_path = "/Users/matthewburkhard/.ssh/id_rsa.pub"

# Server Config
server_name     = "CS2 Server"
max_players     = 10
tickrate        = 128
game_mode       = "competitive"
default_map     = "de_dust2"
server_password = ""  # Empty = no password to join
rcon_password   = "<REDACTED>"  # Strong password

# Steam (GSLT present but credentials missing)
gslt = "<REDACTED>"
# MISSING: steam_username
# MISSING: steam_password

# Workshop (configured but untested)
workshop_collection_id = ""
workshop_start_map_id  = ""

# Mapcycle
mapcycle = ["de_dust2", "de_mirage", "de_inferno", "de_nuke", "de_overpass"]

# Custom CVARs (can add any server settings)
server_cvars = {}
```

## How to Verify Current State

### Check Infrastructure
```bash
cd /Users/matthewburkhard/Projects/CS2Server/CS2Server
terraform validate  # Should succeed
terraform plan      # Should show no changes if already applied
terraform output    # Shows IP and connection info
```

### Check Remote Server
```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw public_ip)

# Check cloud-init completed
sudo cloud-init status  # Should show "done"

# Check Docker service
sudo systemctl status cs2.service  # Should be active but failing

# Check container logs
sudo docker logs -f cs2-server  # Shows 0x202 errors

# Check config files
ls -la /opt/cs2-server/game/csgo/cfg/  # Should show all 6 configs
```

### Destroy and Rebuild
```bash
terraform destroy -auto-approve  # Clean slate
terraform apply -auto-approve    # Redeploy fresh
```

## Recommended Next Steps

1. **Decision Point**: Choose Option A, B, or C above
   
2. **If Option A** (recommended for testing):
   - Add steam_username and steam_password variables
   - Update Docker environment variables in user_data.sh.tftpl
   - Add credentials to terraform.tfvars
   - Run `terraform destroy && terraform apply`
   - SSH to instance and monitor: `sudo docker logs -f cs2-server`
   - If successful, CS2 will download (~30GB), server will start
   - Connect via: `connect IP:27015` in CS2 console
   
3. **Test Configuration**:
   - Verify all 6 config files load correctly
   - Test switching game modes (update terraform.tfvars game_mode)
   - Test Workshop maps if desired
   - Test RCON commands
   
4. **Security Hardening**:
   - If Option A works, upgrade to Option B (Secrets Manager)
   - Rotate RCON password if exposed
   - Consider Steam Guard app password instead of main password

## Key Lessons Learned

1. **CS2 ≠ CS:GO**: Different app IDs (730 vs 740)
2. **GSLT ≠ Download Auth**: GSLT is for runtime server listing, not for downloading files
3. **Anonymous Download Blocked**: Valve changed CS2 dedicated server distribution to require authentication
4. **Docker Inherits Auth Issues**: Community Docker images face same SteamCMD authentication requirements
5. **Infrastructure Can Be Perfect**: Even with flawless Terraform/AWS setup, game-specific requirements can block deployment

## Success Criteria

**Phase 1: Deployment (Current)**
- [x] Terraform configuration complete
- [x] AWS infrastructure deployed
- [x] Docker setup functional
- [x] CS2 downloading (in progress)
- [ ] Server starts and listens on port 27015/udp
- [ ] Can connect from CS2 client
- [ ] Game mode configs load correctly
- [ ] RCON access functional

**Phase 2: Enhancements (Next)**
- [ ] Workshop maps integrated
- [ ] Custom map rotation working
- [ ] Plugin system (CounterStrikeSharp or Metamod)
- [ ] Admin commands configured
- [ ] Practice mode utilities added
- [ ] Additional game modes deployed
- [ ] Server monitoring/stats implemented

---

**Ready for enhancement phase once download completes!**
Current Status

### Server Deployment
✅ Infrastructure deployed (EC2, networking, security groups)  
✅ Docker installed and running  
✅ CS2 downloading (~61.5GB total, estimated 30-40 min)  
⏳ Waiting for download completion  
⏳ Server will auto-start when download finishes

### Monitoring Progress
```bash
# Check download status
ssh -i ~/.ssh/id_rsa ubuntu@3.139.108.216 "sudo journalctl -u cs2.service -f"

# Check if server is ready
ssh -i ~/.ssh/id_rsa ubuntu@3.139.108.216 "sudo docker logs cs2-server | tail -20"
```

### Connect to Server
```
connect 3.139.108.216:27015
```

## Next Phase: Enhancements 🚀

Now that the server is operational, here are enhancement opportunities:

### 1. Custom Maps & Workshop Content
**Current**: Default map pool (dust2, mirage, inferno, nuke, overpass)

**Enhancements**:
- Add Workshop map collections via `workshop_collection_id`
- Custom map rotations for different game modes
- Community map support (aim maps, surf, bhop, kz)
- Automatic map downloads for players

**Implementation**: Update `terraform.tfvars`:
```hcl
workshop_collection_id = "your-collection-id"
workshop_start_map_id  = "your-map-id"
mapcycle = ["de_dust2", "de_ancient", "aim_map", "surf_beginner"]
```

### 2. Server Plugins & Modifications
**Current**: Vanilla CS2 server

**Enhancement Ideas**:
- **CounterStrikeSharp** (C# plugin framework)
- **Metamod:Source** (plugin loader)
- **SourceMod** (scripting framework)
- Custom game modes (retake, executes, 1v1 arena)
- Admin tools (ban system, reserved slots)
- Statistics & ranking systems
- Anti-cheat extensions

**Implementation**: Use Docker volume mounts or `CS2_CFG_URL` to deploy plugins

### 3. In-Game Commands & RCON
**Current**: Basic RCON access configured

**Enhancement Ideas**:
- **Admin Commands**: Kick, ban, switch teams, change map
- **Practice Mode Commands**: sv_cheats, bot commands, grenade lineup tools
- **Game Mode Switching**: Load different configs on-the-fly
- **Server Management**: Restart, update, backup commands
- **Custom Aliases**: Bind complex command sequences

**Example Commands**:
```
rcon_password <your_password>
rcon changelevel de_mirage
rcon mp_warmup_end
rcon sv_cheats 1
rcon bot_add_ct
rcon exec gamemode_deathmatch
```

### 4. Advanced Game Mode Configurations
**Current**: 4 pre-configured modes (competitive, casual, deathmatch, practice)

**Enhancement Ideas**:
- **Retake**: 5v5 post-plant scenarios
- **EError Messages Lie**: "Auth failed" (0x202) actually meant "no disk space" - always verify error codes against source
2. **Check Disk Requirements First**: CS2 needs 50-60GB; default EC2 volumes are 8GB
3. **Docker Simplified Everything**: Avoided complex SteamCMD issues by using community image
4. **Anonymous Login Works**: CS2 (free-to-play) doesn't require Steam credentials for dedicated server download
5. **Infrastructure Matters**: Proper EBS volume configuration was the entire solution

**Implementation**: Add new template configs in `templates/` directory

### 5. Server Customization via CVARs
**Current**: Basic server CVARs configured, `server_cvars` map available

**Enhancement Ideas**:
```hcl
server_cvars = {
  # Gameplay tweaks
  "mp_roundtime"                  = "2.5"
  "mp_freezetime"                 = "12"
  "mp_buytime"                    = "45"
  "mp_buy_anywhere"               = "1"
  "sv_alltalk"                    = "1"
  
  # Training/practice
  "sv_infinite_ammo"              = "1"
  "sv_grenade_trajectory"         = "1"
  "ammo_grenade_limit_total"      = "6"
  
  # Server performance
  "sv_maxrate"                    = "0"
  "sv_minrate"                    = "128000"
  "sv_maxcmdrate"                 = "128"
}
```

### 6. Monitoring & Analytics
**Current**: Basic systemd logging

**Enhancement Ideas**:
- Player statistics tracking
- Server performance metrics (FPS, tick rate)
- Match history and demos
- Player rankings and leaderboards
- Discord bot for server status
- Web-based admin panel

### 7. Multi-Server Setup
**Current**: Single competitive server

**Enhancement Ideas**:
- Deploy multiple servers for different modes
- Load balancer for auto-scaling
- Regional deployment (EU, NA, Asia)
- Practice server + competitive server
- Test server for plugin development

## Immediate Action Items - Phase 1 Deployment Testing

### Step 1: Configure Plugin Mode
Edit `terraform.tfvars` and set your desired plugin mode:

```hcl
# Choose one: vanilla, retakes, practice-plus, deathmatch-custom
plugin_mode = "retakes"

# Other required settings
gslt = "YOUR_GSLT_TOKEN"  # Get from steamcommunity.com/dev/managegameservers
rcon_password = "your-secure-password"
```

### Step 2: Deploy the Server
```bash
terraform validate  # Ensure config is valid
terraform plan      # Review what will be deployed
terraform apply     # Deploy the infrastructure
```

Deployment takes ~3-5 minutes for infrastructure + 30-40 minutes for CS2 download.

### Step 3: Monitor Installation Progress
```bash
# Get server IP
terraform output

# SSH to server
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw public_ip)

# Watch installation logs
sudo cloud-init status --wait  # Wait for bootstrap to complete
sudo journalctl -u cs2.service -f  # Watch server logs

# Check plugin installation
ls -la /opt/cs2-server/game/csgo/addons/counterstrikesharp/
```

### Step 4: Verify Plugins Loaded
Once server starts, check logs for:
```
[CounterStrikeSharp] Loading CounterStrikeSharp v1.x.x
[CounterStrikeSharp] Loaded plugin: CS2Retake (or PracticeMode, Deathmatch)
```

### Step 5: Connect and Test
```
# In CS2 console
connect <server_ip>:27015

# Test RCON
rcon_password your-secure-password
rcon status
```

### Step 6: Test Plugin Features
- **Retakes**: Join CT or T, get auto-loadout, practice post-plant scenarios
- **Practice-Plus**: Type `.noclip`, `.god`, `.bot` in chat
- **Deathmatch-Custom**: Instant respawn, weapon menu on spawn

### Step 7: Teardown When Done
```bash
terraform destroy  # Remove all infrastructure
```

---

## Testing Checklist

- [ ] Server deploys successfully
- [ ] CS2 downloads without errors
- [ ] CounterStrikeSharp loads
- [ ] Chosen plugin loads without errors
- [ ] Can connect from CS2 client
- [ ] Plugin features work as expected
- [ ] RCON commands functional
- [ ] Server runs stable for 30+ minutes

---

## Next Enhancements (Post Phase 1)

1. **Test All 3 Plugin Modes**: Deploy with retakes, practice-plus, deathmatch-custom
2. **Add Executes & Prefire Plugins**: Find community plugins and add URLs
3. **Multi-Server Architecture**: Deploy 3 simultaneous servers (Phase 2)
4. **Web Dashboard**: Start Flask/FastAPI backend (Phase 3)
5. **Pre-bake AMI**: Build AMI with CS2 pre-installed for faster startup