variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description = "EC2 instance type for the CS2 server."
  type        = string
  default     = "t3.medium"
}

variable "use_spot_instance" {
  description = "Use spot instance instead of on-demand for cost savings (70% cheaper but can be interrupted)."
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for spot instances. Default empty means on-demand price (recommended)."
  type        = string
  default     = ""
}

variable "spot_interruption_behavior" {
  description = "What to do when spot instance is interrupted: terminate, stop, or hibernate."
  type        = string
  default     = "terminate"
  
  validation {
    condition     = contains(["terminate", "stop", "hibernate"], var.spot_interruption_behavior)
    error_message = "Spot interruption behavior must be: terminate, stop, or hibernate."
  }
}

variable "project_name" {
  description = "Name used for tagging and resource prefixes."
  type        = string
  default     = "cs2-server"
}

variable "public_key_path" {
  description = "Path to the SSH public key used for EC2 access."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to the instance."
  type        = string
  default     = "0.0.0.0/0"
}

variable "cs2_allowed_cidr" {
  description = "CIDR allowed to access the CS2 UDP ports."
  type        = string
  default     = "0.0.0.0/0"
}

variable "cs2_app_id" {
  description = "Steam app ID for the CS2 dedicated server."
  type        = number
  default     = 730
}

variable "gslt" {
  description = "Steam Game Server Login Token. Leave empty to skip service start."
  type        = string
  default     = ""
  sensitive   = true
}

variable "server_name" {
  description = "Server name shown in the browser."
  type        = string
  default     = "CS2 Server"
}

variable "server_password" {
  description = "Password required to join the server. Leave empty for public access."
  type        = string
  default     = ""
  sensitive   = true
}

variable "rcon_password" {
  description = "RCON password for the server."
  type        = string
  sensitive   = true
}

variable "max_players" {
  description = "Maximum players allowed on the server."
  type        = number
  default     = 10
}

variable "tickrate" {
  description = "Server tickrate (64 or 128). Higher tickrate = more responsive but more CPU intensive."
  type        = number
  default     = 64
  validation {
    condition     = contains([64, 128], var.tickrate)
    error_message = "Tickrate must be either 64 or 128."
  }
}

variable "game_mode" {
  description = "Default game mode: competitive, casual, deathmatch, or practice."
  type        = string
  default     = "competitive"
  validation {
    condition     = contains(["competitive", "casual", "deathmatch", "practice"], var.game_mode)
    error_message = "Game mode must be one of: competitive, casual, deathmatch, practice."
  }
}

variable "default_map" {
  description = "Default map to load on startup."
  type        = string
  default     = "de_dust2"
}

variable "workshop_collection_id" {
  description = "Steam Workshop collection ID for custom maps. Leave empty to disable Workshop."
  type        = string
  default     = ""
}

variable "workshop_start_map_id" {
  description = "Steam Workshop map ID to start with. Required if workshop_collection_id is set."
  type        = string
  default     = ""
}

variable "mapcycle" {
  description = "Map cycle file name (without .txt). Leave empty to use default."
  type        = string
  default     = ""
}

variable "server_cvars" {
  description = "Additional CS2 server CVARs as key-value pairs. These override defaults in server.cfg."
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "cs2-server"
    ManagedBy = "terraform"
  }
}
