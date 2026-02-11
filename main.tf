locals {
  name = var.project_name

  # Game mode to config file mapping
  game_mode_config = {
    competitive = "gamemode_competitive"
    casual      = "gamemode_casual"
    deathmatch  = "gamemode_deathmatch"
    practice    = "practice"
  }

  # Rendered config files
  server_cfg = templatefile("${path.module}/templates/server.cfg.tftpl", {
    server_name      = var.server_name
    server_password  = var.server_password
    rcon_password    = var.rcon_password
    max_players      = var.max_players
    tickrate         = var.tickrate
    game_mode_config = local.game_mode_config[var.game_mode]
  })

  autoexec_cfg = templatefile("${path.module}/templates/autoexec.cfg.tftpl", {
    server_name = var.server_name
    mapcycle    = var.mapcycle
  })

  gamemode_competitive_cfg = templatefile("${path.module}/templates/gamemode_competitive.cfg.tftpl", {})
  gamemode_casual_cfg      = templatefile("${path.module}/templates/gamemode_casual.cfg.tftpl", {})
  gamemode_deathmatch_cfg  = templatefile("${path.module}/templates/gamemode_deathmatch.cfg.tftpl", {})
  practice_cfg             = templatefile("${path.module}/templates/practice.cfg.tftpl", {})
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "server" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-subnet"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "server" {
  key_name   = "${local.name}-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "server" {
  name        = "${local.name}-sg"
  description = "Security group for the CS2 server."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "CS2 server"
    from_port   = 27015
    to_port     = 27015
    protocol    = "udp"
    cidr_blocks = [var.cs2_allowed_cidr]
  }

  ingress {
    description = "CS2 GOTV"
    from_port   = 27020
    to_port     = 27020
    protocol    = "udp"
    cidr_blocks = [var.cs2_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.server.id
  vpc_security_group_ids      = [aws_security_group.server.id]
  key_name                    = aws_key_pair.server.key_name
  associate_public_ip_address = true
  
  # Spot instance configuration (optional)
  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price                      = var.spot_max_price != "" ? var.spot_max_price : null
        spot_instance_type             = "one-time"
        instance_interruption_behavior = var.spot_interruption_behavior
      }
    }
  }
  
  root_block_device {
    volume_size = 80  # GB - CS2 needs ~35GB + extraction space
    volume_type = "gp3"
    encrypted   = true
  }
  
  user_data                   = templatefile("${path.module}/user_data.sh.tftpl", {
    cs2_app_id                = var.cs2_app_id
    server_name               = var.server_name
    default_map               = var.default_map
    gslt                      = var.gslt
    max_players               = var.max_players
    tickrate                  = var.tickrate
    game_mode                 = var.game_mode
    workshop_collection_id    = var.workshop_collection_id
    workshop_start_map_id     = var.workshop_start_map_id
    server_cvars              = var.server_cvars
    server_cfg                = local.server_cfg
    autoexec_cfg              = local.autoexec_cfg
    gamemode_competitive_cfg  = local.gamemode_competitive_cfg
    gamemode_casual_cfg       = local.gamemode_casual_cfg
    gamemode_deathmatch_cfg   = local.gamemode_deathmatch_cfg
    practice_cfg              = local.practice_cfg
  })
  user_data_replace_on_change = true

  tags = {
    Name = local.name
  }
}
