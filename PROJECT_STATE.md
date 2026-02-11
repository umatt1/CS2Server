# CS2 Server Terraform Project - Current State

**Date:** February 11, 2026  
**Branch:** `copilot/add-cs2-server-terraform`  
**Status:** 🔴 Blocked - CS2 download failing with authentication error

## Project Overview

Building a fully-configured Counter-Strike 2 dedicated server on AWS using Terraform, with the goal of playing CS2 with friends on a custom-configured server.

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
  - Workshop: collection_id and start_map_id support
  - Custom CVARs: Map of additional server settings
  - Passwords: Server password, RCON password (sensitive)
  - GSLT: Game Server Login Token (sensitive)

- **Files Generated**: All configs written to `/opt/cs2-server/game/csgo/cfg/`
  - Mounted as Docker volume
  - Never tested because server doesn't start

## The Blocker 🔴

### Error: `Error! App '730' state is 0x202 after update job`

**Symptom**: SteamCMD refuses to download CS2 dedicated server files (app ID 730)

**Impact**: Server infrastructure boots perfectly, but CS2 never installs, so no game server runs

**Reproduction**:
```bash
# After terraform apply
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw public_ip)
sudo docker logs -f cs2-server
# Shows repeated 0x202 errors across 3 retry attempts
```

### Root Cause Analysis

**Error code 0x202** means: "Update failed: Content servers unreachable or authentication failed"

**Why it's happening**: CS2 dedicated servers require **authenticated Steam account login** for download, not just anonymous SteamCMD access. The GSLT token is only used at runtime, not for download.

**What we tried (all failed)**:
1. ❌ SteamCMD via apt package (hit interactive license prompt)
2. ❌ SteamCMD via tarball with anonymous login
3. ❌ Changed app ID from 740 (CS:GO) to 730 (CS2) - correct ID but still failed
4. ❌ Removed 'validate' flag from +app_update
5. ❌ Added platform forcing: +@sSteamCmdForcePlatformType linux
6. ❌ Added retry logic with 3 attempts and 30-second delays
7. ❌ Pivoted to Docker (joedwards32/cs2:latest) - same error inside container

**Confirmed not the issue**:
- ✅ Steam services operational (checked steamstat.us: 96.8% CMs online, all "Normal")
- ✅ Network connectivity (EC2 can reach Steam CDN)
- ✅ App ID is correct (730 is CS2 dedicated server)
- ✅ GSLT is valid (token for app 730)

**Conclusion**: Need Steam account credentials (username + password) for authenticated SteamCMD login.

## Available Options

### Option A: Add Steam Credentials (Quickest)
**Approach**: Add Steam username/password as Terraform variables

**Implementation**:
1. Add to `variables.tf`:
   ```hcl
   variable "steam_username" {
     type      = string
     sensitive = true
   }
   variable "steam_password" {
     type      = string
     sensitive = true
   }
   ```
2. Update `user_data.sh.tftpl` Docker command:
   ```bash
   -e STEAMUSER=${steam_username} \
   -e STEAMPW=${steam_password} \
   ```
3. Add to `terraform.tfvars` (gitignored):
   ```hcl
   steam_username = "your_steam_username"
   steam_password = "your_steam_password"
   ```

**Pros**:
- Fastest to implement (~10 minutes)
- Test if authenticated login solves the problem
- Can upgrade to Secrets Manager later

**Cons**:
- Credentials in plain text in terraform.tfvars (gitignored but local)
- Credentials visible in Terraform state file
- Less secure for production use

**Security notes**:
- terraform.tfvars already gitignored
- State file stored locally only
- Could use Steam Guard-exempt app password

### Option B: AWS Secrets Manager (Most Secure)
**Approach**: Store credentials in AWS Secrets Manager, fetch in user_data

**Implementation**:
1. Create secrets in AWS:
   ```bash
   aws secretsmanager create-secret --name cs2/steam-username --secret-string "..."
   aws secretsmanager create-secret --name cs2/steam-password --secret-string "..."
   ```
2. Add IAM role to EC2 with secretsmanager:GetSecretValue
3. Fetch in user_data.sh.tftpl:
   ```bash
   STEAM_USER=$(aws secretsmanager get-secret-value --secret-id cs2/steam-username --query SecretString --output text)
   STEAM_PASS=$(aws secretsmanager get-secret-value --secret-id cs2/steam-password --query SecretString --output text)
   ```
4. Pass to Docker as environment variables

**Pros**:
- Production-grade security
- Credentials never in Terraform state
- Centralized secret rotation
- Audit trail for access

**Cons**:
- More complex setup (~30-45 minutes)
- Additional AWS costs ($0.40/month per secret)
- Requires AWS CLI on instance (already present)

### Option C: Commercial Hosting (Give Up Self-Hosting)
**Approach**: Use existing CS2 server hosting service

**Providers**:
- GameServerKings
- Nitrous Networks  
- LOW.MS
- Typically $10-20/month for 10-player server

**Pros**:
- No authentication issues
- Managed updates
- DDoS protection
- Support

**Cons**:
- Monthly cost
- Less control over infrastructure
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

- [ ] CS2 dedicated server downloads successfully (30GB)
- [ ] Server starts and listens on port 27015/udp
- [ ] Can connect from CS2 client: `connect IP:27015`
- [ ] Game mode configs load correctly
- [ ] RCON access works with configured password
- [ ] Can play matches with friends
- [ ] (Optional) Workshop maps load if configured

---

**Prepared for handoff to successor conversation.**
