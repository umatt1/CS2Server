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

### Plugins & Mods

To add plugins (CounterStrikeSharp, SourceMod, etc.):

1. SSH to the server
2. Install the plugin framework to `/opt/cs2-server/game/csgo/`
3. Configure in `addons/` directory
4. Restart the container: `sudo systemctl restart cs2`

**Note:** Plugin installation is currently manual. Terraform automation for plugins is a future enhancement. Plugins installed in `/opt/cs2-server` persist across container restarts.
