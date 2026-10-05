# Terraform AWS Infrastructure Assignment

## Student Information

- **Name:** Manvendra Singh
- **Course:** BCA
- **University:** Maharishi University of Information Technology (MUIT), Noida
- **Project:** Terraform AWS Infrastructure Deployment

---

# 1. Project Overview

This project demonstrates Infrastructure as Code (IaC) using **Terraform** to provision and deploy Flask and Express applications on AWS.

The assignment is divided into three parts:

- **Part 1:** Deploy Flask backend and Express frontend on a single EC2 instance.
- **Part 2:** Deploy Flask backend and Express frontend on separate EC2 instances using a custom VPC, subnets and security groups.
- **Part 3:** Deploy containerized Flask and Express applications using Amazon ECR, ECS Fargate and an Application Load Balancer.

All infrastructure resources are provisioned using Terraform.

---

# 2. Technologies Used

- Terraform
- AWS EC2
- AWS VPC
- AWS Subnets
- AWS Internet Gateway
- AWS Route Tables
- AWS Security Groups
- Amazon ECR
- Amazon ECS
- AWS Fargate
- Application Load Balancer (ALB)
- Docker
- Flask
- Node.js
- Express.js
- Ubuntu Linux
- AWS CLI
- Git and GitHub

---

# 3. Project Structure

```text
Terraform_Manvendra/
│
├── part1/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── user-data.sh
│
├── part2/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend-user-data.sh
│   └── frontend-user-data.sh
│
├── part3/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── screenshots/
│   ├── part1/
│   ├── part2/
│   └── part3/
│
└── README.md












. Part 1 – Single EC2 Deployment
Objective
Deploy both the Flask backend and Express frontend on a single EC2 instance using Terraform.
Infrastructure
Terraform provisions:
- AWS EC2 instance
- Security Group
- Ubuntu 24.04 AMI
- Public IP
- User-data configuration
The user-data script automatically:
- Installs Python
- Installs Flask
- Installs Node.js
- Installs Express
- Creates the backend application
- Creates the frontend application
- Starts both applications as systemd services
Application Ports
Application	Port
Flask Backend	5000
Express Frontend	3000


Terraform Commands
cd part1
terraform init
terraform validate
terraform plan
terraform apply

Testing
Frontend:
http://<EC2-PUBLIC-IP>:3000

Backend:
http://<EC2-PUBLIC-IP>:5000

The frontend provides a form for submitting a To-Do item.
The backend processes the submitted data and returns a JSON response containing:
- Message
- Item ID
- Item Name
- Item Description
5. Part 2 – Separate EC2 Deployment
Objective
Deploy the Flask backend and Express frontend on separate EC2 instances using a custom VPC and subnet architecture.
Network Architecture
                    Internet
                       |
                Internet Gateway
                       |
                 Custom VPC
                10.20.0.0/16
                       |
          +------------+------------+
          |                         |
          |                         |
 Frontend Subnet              Backend Subnet
 10.20.1.0/24                 10.20.2.0/24
          |                         |
          |                         |
 Frontend EC2                 Backend EC2
 Express :3000                Flask :5000
          |                         |
          +-------- HTTP -----------+

Infrastructure
Terraform provisions:
- Custom VPC
- Internet Gateway
- Two public subnets
- Route table
- Route table associations
- Frontend security group
- Backend security group
- Frontend EC2 instance
- Backend EC2 instance
Backend
The Flask backend runs on:
Port: 5000

The backend EC2 private IP is used by the frontend application for communication.
Frontend
The Express frontend runs on:
Port: 3000

The frontend communicates with the backend using the backend EC2 private IP.
Terraform Commands
cd part2
terraform init
terraform validate
terraform plan
terraform apply

Testing
Frontend:
http://<FRONTEND-PUBLIC-IP>:3000

Backend:
http://<BACKEND-PUBLIC-IP>:5000

The frontend form successfully communicates with the Flask backend and receives the JSON response.
6. Part 3 – ECR + ECS Fargate + ALB
Objective
Deploy the Flask backend and Express frontend as Docker containers using:
- Amazon ECR
- Amazon ECS
- AWS Fargate
- Application Load Balancer
Architecture
                         Internet
                            |
                            |
                    Application Load
                     Balancer (ALB)
                            |
                +-----------+-----------+
                |                       |
                |                       |
        Frontend Target Group    Backend Target Group
             Port 3000                Port 5000
                |                       |
                |                       |
          ECS Fargate             ECS Fargate
          Frontend Task           Backend Task
                |                       |
                |                       |
        Express Container         Flask Container
                |                       |
                +-----------+-----------+
                            |
                           ECR
                    +-------+-------+
                    |               |
               Frontend ECR    Backend ECR

AWS Resources
Part 3 provisions:
- Custom VPC
- Internet Gateway
- Two public subnets
- Route table
- Security groups
- Amazon ECR repositories
- ECS cluster
- ECS execution IAM role
- ECS Fargate task definitions
- ECS services
- Application Load Balancer
- Frontend target group
- Backend target group
- ALB listener
- ALB listener rule
ECR Repositories
Backend
terraform-part3-backend

Frontend
terraform-part3-frontend

Docker images were built and pushed to Amazon ECR.
Example:
docker build -t terraform-part3-backend ./backend
docker build -t terraform-part3-frontend ./frontend

The images were tagged with their respective ECR repository URLs and pushed using Docker and AWS ECR authentication.
7. ECS Configuration
The project uses AWS Fargate to run the containers without managing EC2 servers for the ECS workload.
ECS Cluster
Terraform-Part3-ECS-Cluster

Backend Service
Terraform-Part3-Backend-Service

Container port:
5000

Frontend Service
Terraform-Part3-Frontend-Service

Container port:
3000

Each service runs with a desired count of one task.
8. Application Load Balancer
The Application Load Balancer provides a single public endpoint for the application.
Default Route
The ALB forwards normal frontend requests to the Express frontend service.
Backend Route
The following paths are routed to the Flask backend:
/health
/submittodoitem
/submittodoitem/*

Therefore, the backend can be accessed through the same ALB.
9. Final Application URLs
Application
http://tf-part3-alb-10365191.ap-south-1.elb.amazonaws.com

Backend Health Check
http://tf-part3-alb-10365191.ap-south-1.elb.amazonaws.com/health

The /health endpoint successfully returns the backend health response.
10. Terraform Commands Used
The following commands were used during the project.
Initialize Terraform
terraform init

Validate Configuration
terraform validate

Format Terraform Files
terraform fmt

Create Execution Plan
terraform plan

Apply Infrastructure
terraform apply

View Terraform Outputs
terraform output

11. Terraform Best Practices Used
The project follows basic Terraform best practices:
- Infrastructure is defined as code.
- Variables are separated into variables.tf.
- Outputs are defined in outputs.tf.
- Resource configuration is maintained in main.tf.
- Reusable values are managed through Terraform variables.
- AWS region is configurable.
- Resource names are organized using project naming variables.
- Security groups restrict application traffic to required ports.
- ECS uses IAM execution roles.
- ECR image scanning is enabled on push.
- Terraform formatting and validation were performed.
12. Testing and Verification
The deployments were tested after Terraform provisioning.
Part 1
Verified:
- EC2 instance running
- Flask backend accessible
- Express frontend accessible
- Form submission successful
- JSON response generated successfully
Part 2
Verified:
- Custom VPC created
- Frontend and backend EC2 instances running
- Frontend accessible through public IP
- Backend accessible
- Frontend successfully communicates with backend
- Form submission successful
Part 3
Verified:
- ECR repositories created
- Docker images pushed to ECR
- ECS cluster created
- Backend ECS service running
- Frontend ECS service running
- ALB created
- Frontend target healthy
- Backend target healthy
- /health endpoint working
- /submittodoitem endpoint working
- Frontend form submission successful through ALB
13. Final Terraform Outputs
Important Part 3 resources:
Resource	Value
VPC	vpc-036a333cb93016acc
ECS Cluster	Terraform-Part3-ECS-Cluster
Backend Service	Terraform-Part3-Backend-Service
Frontend Service	Terraform-Part3-Frontend-Service
ALB	tf-part3-alb-10365191.ap-south-1.elb.amazonaws.com
Backend SG	sg-03394cd1b6b5b5175
Frontend SG	sg-0e48acd32abc028b6
ALB SG	sg-0710a04c82a7b8110
