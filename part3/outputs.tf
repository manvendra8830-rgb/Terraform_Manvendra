output "vpc_id" {
  description = "Part 3 VPC ID"
  value       = aws_vpc.part3.id
}

output "ecr_backend_repository_url" {
  description = "Backend ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "Frontend ECR repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.part3.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "application_url" {
  description = "Application URL through the ALB"
  value       = "http://${aws_lb.app.dns_name}"
}

output "backend_health_url" {
  description = "Backend health endpoint through the ALB"
  value       = "http://${aws_lb.app.dns_name}/health"
}

output "backend_security_group_id" {
  description = "Backend ECS security group ID"
  value       = aws_security_group.backend.id
}

output "frontend_security_group_id" {
  description = "Frontend ECS security group ID"
  value       = aws_security_group.frontend.id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}
