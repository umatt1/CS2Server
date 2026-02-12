# CS2Server
I want to play counterstrike with my friends 

## Terraform setup

1. Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the plan:

```bash
terraform plan
```

4. Apply when ready:

```bash
terraform apply
```

## CS2 server notes

### Architecture

This setup uses **Docker** to run the CS2 dedicated server, avoiding SteamCMD installation issues and providing:
- **Reliable deployment**: Community-maintained Docker image ([joedwards32/cs2](https://hub.docker.com/r/joedwards32/cs2))
- **Easy updates**: Restart the container to pull the latest CS2 version
- **Config management**: Your Terraform templates are mounted into the container
- **Consistent behavior**: Same environment across deployments

The server runs in a Docker container with your custom configs mounted at `/home/steam/cs2-dedicated`.

### Quick Start

1. Get a Steam Game Server Login Token (GSLT) at: https://steamcommunity.com/dev/managegameservers
2. Update `gslt`, `server_name`, and `rcon_password` in `terraform.tfvars`
3. Run `terraform apply`

Once Terraform finishes, it will output the public IP address and connect command.

### Game Modes

The server supports multiple game modes via the `game_mode` variable:

- **competitive** (default): 5v5 MR12 format, 128 tick recommended
- **casual**: Relaxed rules, free armor, larger teams
- **deathmatch**: Free-for-all respawn mode, instant action
- **practice**: Infinite money, grenades, sv_cheats enabled for training

To switch modes, update `game_mode` in `terraform.tfvars` and run `terraform apply`.

### Workshop Maps

To use Steam Workshop maps:

1. Create a Workshop collection or find the collection ID from a URL like:
   `steamcommunity.com/sharedfiles/filedetails/?id=COLLECTION_ID`

2. Get a map ID from the Workshop map page URL:
   `steamcommunity.com/sharedfiles/filedetails/?id=MAP_ID`

3. Set in `terraform.tfvars`:
   ```hcl
   workshop_collection_id = "123456789"
   workshop_start_map_id  = "987654321"
   ```

4. Run `terraform apply`

The server will download and host Workshop maps automatically.

### Custom Configuration

#### Server CVARs

Override any CS2 server setting using the `server_cvars` map in `terraform.tfvars`:

```hcl
server_cvars = {
  "mp_roundtime"   = "2.5"
  "mp_freezetime"  = "12"
  "sv_alltalk"     = "1"
  "mp_buytime"     = "30"
}
```

See the [CS2 CVAR list](https://developer.valvesoftware.com/wiki/List_of_Counter-Strike_2_console_commands_and_variables) for available options.

#### Tickrate

Set `tickrate = 128` for competitive play (requires more CPU) or `tickrate = 64` for casual/lower cost.

#### Server Password

Set `server_password` in `terraform.tfvars` to restrict access. Leave empty for a public server.

### Hot-Reload Configuration (Without Rebuild)

**Note:** Changes to `terraform.tfvars` require `terraform apply`, which rebuilds the instance. To modify configs without destroying the server:

1. SSH to the server:
   ```bash
   ssh -i /path/to/key ubuntu@<public_ip>
   ```

2. Edit configs in `/opt/cs2-server/game/csgo/cfg/`:
   ```bash
   sudo nano /opt/cs2-server/game/csgo/cfg/server.cfg
   ```

3. Restart the Docker container to apply changes:
   ```bash
   sudo systemctl restart cs2
   ```
   
   Or reload via RCON:
   ```bash
   # Requires RCON connection
   rcon exec server.cfg
   ```

**Docker Advantage:** Config changes persist across container restarts since they're in `/opt/cs2-server` on the host.

**Server Updates:** To update CS2 to the latest version:
```bash
sudo docker pull joedwards32/cs2:latest
sudo systemctl restart cs2
```

**Future Enhancement:** To enable hot-reload via Terraform, consider using `null_resource` with `remote-exec` provisioner or a config management tool like Ansible.

### Configuration Files

The server uses these config templates (in `templates/`):

- `server.cfg.tftpl`: Base server settings (hostname, passwords, tick, logging)
- `autoexec.cfg.tftpl`: Auto-executed on startup
- `gamemode_competitive.cfg.tftpl`: 5v5 competitive settings
- `gamemode_casual.cfg.tftpl`: Casual mode settings
- `gamemode_deathmatch.cfg.tftpl`: Deathmatch settings
- `practice.cfg.tftpl`: Practice mode with sv_cheats

To customize further, edit the templates and run `terraform apply`.

### Persistent Storage (EBS Volume)

**🚀 Fast redeployments!** CS2 game files (~35GB) are stored on a persistent EBS volume that survives instance destruction.

**How it works:**
- First deployment: CS2 downloads normally (~15-30 minutes depending on network)
- Subsequent deployments: CS2 data is already there (instant startup)
- The EBS volume persists even when you run `terraform destroy`

**Managing the data volume:**

```bash
# Normal destroy - KEEPS CS2 data volume for fast redeployment
terraform destroy

# Complete teardown - DELETES CS2 data volume and all game files
terraform destroy -var="delete_cs2_data_on_destroy=true"

# Alternative: Destroy only the instance, keep volume
terraform destroy -target=aws_instance.server
```

**Multi-server deployments:**
The current setup supports a single server. For multiple servers:
1. Use `count` or `for_each` on the instance and volume resources
2. Each server gets its own tagged EBS volume
3. Volumes automatically reattach to their corresponding instances

**Volume info:**
- Size: 50GB (adjustable in `aws_ebs_volume.cs2_data`)
- Type: gp3 (encrypted)
- Mounted at: `/opt/cs2-server` on the instance
- Cost: ~$4/month when kept (vs ~30min download time)

### Connecting In-Game

Use the `cs2_connect` output from Terraform:

```
connect <ip>:27015
```

If a password is set:
```
connect <ip>:27015; password yourpassword
```

### RCON Access

RCON password is set via `rcon_password` in `terraform.tfvars`. To use RCON:

1. SSH tunnel (RCON port not exposed publicly by default):
   ```bash
   ssh -L 27015:localhost:27015 ubuntu@<public_ip>
   ```

2. Connect with an RCON tool pointing to `localhost:27015`

### Plugins & Mods ✨ NEW

**Automated plugin installation is now supported!** Set `plugin_mode` in `terraform.tfvars` to automatically install CounterStrikeSharp and community plugins.

#### Available Plugin Modes

- **vanilla**: No plugins (base CS2 server)
- **retakes**: CS2-Retakes plugin for post-plant practice scenarios
- **practice-plus**: Enhanced practice mode with `.noclip`, `.god`, `.bot` commands
- **deathmatch-custom**: Custom deathmatch with weapon menu and instant respawn
- **executes**: Site execute practice (TBD - community plugin needed)
- **prefire**: Angle training mode (TBD - community plugin needed)

#### Usage

```hcl
# In terraform.tfvars
plugin_mode = "retakes"  # Choose your mode
```

Run `terraform apply` and the plugin framework + chosen plugin will be automatically installed during server bootstrap.

**Manual Plugin Installation** (for custom plugins):

1. SSH to the server
2. Install plugin to `/opt/cs2-server/game/csgo/addons/counterstrikesharp/plugins/`
3. Restart: `sudo systemctl restart cs2.service`

Plugins persist across container restarts since they're in `/opt/cs2-server` (mounted volume).
