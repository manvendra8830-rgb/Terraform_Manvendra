output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.part1.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.part1.public_ip
}

output "frontend_url" {
  description = "Express frontend URL"
  value       = "http://${aws_instance.part1.public_ip}:3000"
}

output "backend_url" {
  description = "Flask backend URL"
  value       = "http://${aws_instance.part1.public_ip}:5000"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.part1.id
}
