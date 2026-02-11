output "project_name" {
  value       = var.project_name
  description = "Project name used for tagging and prefixes."
}

output "aws_region" {
  value       = var.aws_region
  description = "AWS region for deployment."
}

output "instance_id" {
  value       = aws_instance.server.id
  description = "EC2 instance ID for the server."
}

output "public_ip" {
  value       = aws_instance.server.public_ip
  description = "Public IP address for the server."
}

output "cs2_connect" {
  value       = "connect ${aws_instance.server.public_ip}:27015"
  description = "In-game console command to connect to the server."
}
