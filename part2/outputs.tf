output "vpc_id" {
  description = "Part 2 VPC ID"
  value       = aws_vpc.part2.id
}

output "frontend_instance_id" {
  description = "Frontend EC2 instance ID"
  value       = aws_instance.frontend.id
}

output "backend_instance_id" {
  description = "Backend EC2 instance ID"
  value       = aws_instance.backend.id
}

output "frontend_public_ip" {
  description = "Public IP address of the Express frontend EC2"
  value       = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  description = "Public IP address of the Flask backend EC2"
  value       = aws_instance.backend.public_ip
}

output "backend_private_ip" {
  description = "Private IP address used by the frontend to reach Flask"
  value       = aws_instance.backend.private_ip
}

output "frontend_url" {
  description = "Express frontend URL"
  value       = "http://${aws_instance.frontend.public_ip}:3000"
}

output "backend_url" {
  description = "Flask backend URL"
  value       = "http://${aws_instance.backend.public_ip}:5000"
}

output "frontend_security_group_id" {
  description = "Frontend security group ID"
  value       = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  description = "Backend security group ID"
  value       = aws_security_group.backend.id
}
