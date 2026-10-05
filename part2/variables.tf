variable "aws_region" {
  description = "AWS region for Terraform Part 2"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR block for the Part 2 VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "frontend_subnet_cidr" {
  description = "CIDR block for frontend subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "backend_subnet_cidr" {
  description = "CIDR block for backend subnet"
  type        = string
  default     = "10.20.2.0/24"
}

variable "frontend_instance_name" {
  description = "Name of the frontend EC2 instance"
  type        = string
  default     = "Terraform-Part2-Frontend-EC2"
}

variable "backend_instance_name" {
  description = "Name of the backend EC2 instance"
  type        = string
  default     = "Terraform-Part2-Backend-EC2"
}
