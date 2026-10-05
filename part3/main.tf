terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =========================================================
# ECR REPOSITORIES
# =========================================================

resource "aws_ecr_repository" "backend" {
  name                 = var.backend_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-Backend-ECR"
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = var.frontend_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-Frontend-ECR"
  }
}

# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "part3" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-VPC"
  }
}

resource "aws_internet_gateway" "part3" {
  vpc_id = aws_vpc.part3.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# =========================================================
# PUBLIC SUBNETS
# =========================================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.part3.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-Public-Subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.part3.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-Public-Subnet-2"
  }
}

# =========================================================
# ROUTE TABLE
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.part3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.part3.id
  }

  tags = {
    Name = "${var.project_name}-Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# =========================================================
# APPLICATION LOAD BALANCER SECURITY GROUP
# =========================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-ALB-SG"
  description = "Security group for Part 3 Application Load Balancer"
  vpc_id      = aws_vpc.part3.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
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
    Name = "${var.project_name}-ALB-SG"
  }
}

# =========================================================
# FRONTEND ECS SECURITY GROUP
# =========================================================

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-Frontend-SG"
  description = "Security group for frontend ECS tasks"
  vpc_id      = aws_vpc.part3.id

  ingress {
    description     = "Express traffic from ALB"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Frontend-SG"
  }
}

# =========================================================
# BACKEND ECS SECURITY GROUP
# =========================================================

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-Backend-SG"
  description = "Security group for backend ECS tasks"
  vpc_id      = aws_vpc.part3.id

  ingress {
    description     = "Flask traffic from ALB"
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Backend-SG"
  }
}

# =========================================================
# ECS CLUSTER
# =========================================================

resource "aws_ecs_cluster" "part3" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.ecs_cluster_name
  }
}

# =========================================================
# IAM ROLE FOR ECS TASK EXECUTION
# =========================================================

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ECS-Execution-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ECS-Execution-Role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# =========================================================
# APPLICATION LOAD BALANCER
# =========================================================

resource "aws_lb" "app" {
  name               = "tf-part3-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

# =========================================================
# FRONTEND TARGET GROUP
# =========================================================

resource "aws_lb_target_group" "frontend" {
  name        = "tf-part3-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.part3.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-Frontend-TG"
  }
}

# =========================================================
# BACKEND TARGET GROUP
# =========================================================

resource "aws_lb_target_group" "backend" {
  name        = "tf-part3-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.part3.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-Backend-TG"
  }
}

# =========================================================
# ALB HTTP LISTENER
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# =========================================================
# BACKEND PATH-BASED ROUTING
# =========================================================

resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = [
        "/submittodoitem",
        "/health",
        "/submittodoitem/*"
      ]
    }
  }
}

# =========================================================
# BACKEND ECS TASK DEFINITION
# =========================================================

resource "aws_ecs_task_definition" "backend" {
  family                   = "terraform-part3-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]

  tags = {
    Name = "${var.project_name}-Backend-Task"
  }
}

# =========================================================
# FRONTEND ECS TASK DEFINITION
# =========================================================

resource "aws_ecs_task_definition" "frontend" {
  family                   = "terraform-part3-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://${aws_lb.app.dns_name}"
        }
      ]
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_lb.app
  ]

  tags = {
    Name = "${var.project_name}-Frontend-Task"
  }
}

# =========================================================
# BACKEND ECS SERVICE
# =========================================================

resource "aws_ecs_service" "backend" {
  name            = var.backend_service_name
  cluster         = aws_ecs_cluster.part3.id
  task_definition = aws_ecs_task_definition.backend.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]

    security_groups = [
      aws_security_group.backend.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name = var.backend_service_name
  }
}

# =========================================================
# FRONTEND ECS SERVICE
# =========================================================

resource "aws_ecs_service" "frontend" {
  name            = var.frontend_service_name
  cluster         = aws_ecs_cluster.part3.id
  task_definition = aws_ecs_task_definition.frontend.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]

    security_groups = [
      aws_security_group.frontend.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name = var.frontend_service_name
  }
}
