variable "aws_region" {
  description = "AWS region for Terraform Part 3"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for Part 3 resources"
  type        = string
  default     = "Terraform-Part3"
}

variable "vpc_cidr" {
  description = "CIDR block for the Part 3 VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.30.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.30.2.0/24"
}

variable "availability_zone_1" {
  description = "First availability zone"
  type        = string
  default     = "ap-south-1a"
}

variable "availability_zone_2" {
  description = "Second availability zone"
  type        = string
  default     = "ap-south-1b"
}

variable "backend_repository_name" {
  description = "ECR repository name for Flask backend"
  type        = string
  default     = "terraform-part3-backend"
}

variable "frontend_repository_name" {
  description = "ECR repository name for Express frontend"
  type        = string
  default     = "terraform-part3-frontend"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "Terraform-Part3-ECS-Cluster"
}

variable "backend_service_name" {
  description = "ECS backend service name"
  type        = string
  default     = "Terraform-Part3-Backend-Service"
}

variable "frontend_service_name" {
  description = "ECS frontend service name"
  type        = string
  default     = "Terraform-Part3-Frontend-Service"
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "backend_container_port" {
  description = "Flask backend container port"
  type        = number
  default     = 5000
}

variable "frontend_container_port" {
  description = "Express frontend container port"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Number of ECS tasks for each service"
  type        = number
  default     = 1
}
