terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "part2" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform-Part2-VPC"
  }
}

# =========================================================
# Internet Gateway
# =========================================================

resource "aws_internet_gateway" "part2" {
  vpc_id = aws_vpc.part2.id

  tags = {
    Name = "Terraform-Part2-IGW"
  }
}

# =========================================================
# Frontend Subnet
# =========================================================

resource "aws_subnet" "frontend" {
  vpc_id                  = aws_vpc.part2.id
  cidr_block              = var.frontend_subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Terraform-Part2-Frontend-Subnet"
  }
}

# =========================================================
# Backend Subnet
# =========================================================

resource "aws_subnet" "backend" {
  vpc_id                  = aws_vpc.part2.id
  cidr_block              = var.backend_subnet_cidr
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Terraform-Part2-Backend-Subnet"
  }
}

# =========================================================
# Route Table
# =========================================================

resource "aws_route_table" "part2" {
  vpc_id = aws_vpc.part2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.part2.id
  }

  tags = {
    Name = "Terraform-Part2-Public-Route-Table"
  }
}

resource "aws_route_table_association" "frontend" {
  subnet_id      = aws_subnet.frontend.id
  route_table_id = aws_route_table.part2.id
}

resource "aws_route_table_association" "backend" {
  subnet_id      = aws_subnet.backend.id
  route_table_id = aws_route_table.part2.id
}

# =========================================================
# Backend Security Group
# =========================================================

resource "aws_security_group" "backend" {
  name        = "terraform-part2-backend-sg"
  description = "Security group for Terraform Part 2 Flask backend"
  vpc_id      = aws_vpc.part2.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask from frontend security group"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [
      aws_security_group.frontend.id
    ]
  }

  ingress {
    description = "Flask public access for testing"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Part2-Backend-SG"
  }
}

# =========================================================
# Frontend Security Group
# =========================================================

resource "aws_security_group" "frontend" {
  name        = "terraform-part2-frontend-sg"
  description = "Security group for Terraform Part 2 Express frontend"
  vpc_id      = aws_vpc.part2.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Express Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Part2-Frontend-SG"
  }
}

# =========================================================
# Backend EC2
# =========================================================

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.backend.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/backend-user-data.sh")

  tags = {
    Name = var.backend_instance_name
    Role = "Flask-Backend"
  }
}

# =========================================================
# Frontend EC2
# =========================================================

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.frontend.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/frontend-user-data.sh",
    {
      backend_private_ip = aws_instance.backend.private_ip
    }
  )

  depends_on = [
    aws_instance.backend
  ]

  tags = {
    Name = var.frontend_instance_name
    Role = "Express-Frontend"
  }
}
