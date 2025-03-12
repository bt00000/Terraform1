// S3 Backend for Terraform State Management, Assuming S3 bucket set up
terraform {
  backend "s3" {
    bucket         = "brennan-terraform-state" # S3 bucket for storing Terraform state
    key            = "terraform/terraform.tfstate"
    dynamodb_table = "brennan-terraform-lock"
    region         = "us-east-1"
    encrypt        = true # Enable encryption for security
  }
}

# Define provider (AWS)
provider "aws" {
  region = "us-east-1"
}

# Create S3 Bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "brennan-terraform-test-bucket"

  lifecycle {
    prevent_destroy = false # Allow Terraform to destroy the bucket
  }

  force_destroy = true # Allows deletion even if bucket has objects
}

# Enable Version Control for S3 Bucket
# Useful for data recovery in case of accidental deletion.
resource "aws_s3_bucket_versioning" "example_versioning" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption for S3 Bucket
# Ensures that all objects are encrypted inside the S3 bucket using AES256 for security
resource "aws_s3_bucket_server_side_encryption_configuration" "example_encryption" {
  bucket = aws_s3_bucket.example_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ----------------- VPC CONFIGURATION -----------------
# Create VPC (private network)
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16" # Defines the range of IPs for the VPC

  tags = {
    Name = "main-vpc"
  }
}

# Create Public Subnet
# A public subnet that assigns IP addresses to instances
# Used to host resources that need internet access
resource "aws_subnet" "public_net" {
  vpc_id                  = aws_vpc.main_vpc.id # Associate with the VPC
  cidr_block              = "10.0.1.0/24"       # Subnet for public resources
  map_public_ip_on_launch = true                # Assigns Public IPs to instances
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

# Create Second Public Subnet (for ALB)
resource "aws_subnet" "public_net_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"  # Different subnet range
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"  # Different AZ from the first subnet

  tags = {
    Name = "public-subnet-2"
  }
}

# Create an Internet Gateway
# Enables internet access for instances in the public subnet
# To allow resources in the public subnet to access the internet, attach an Internet Gateway
resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-gateway"
  }
}

# Create a Route Table for Public Traffic
# Route table so that traffic from the public subnet goes through the Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id # Associate with VPC

  route {
    cidr_block = "0.0.0.0/0"                     # Allow outbound traffic to any IP
    gateway_id = aws_internet_gateway.main_gw.id # Route traffic through the IGW
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Subnet with Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_net.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Second Public Subnet with Route Table
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_net_2.id
  route_table_id = aws_route_table.public_rt.id
}

# ----------------- SECURITY GROUPS -----------------
# Security Group for ALB (Application Load Balancer)
# Allows inbound HTTP (80) and Health Check (8080) traffic
# Allows all outbound traffic
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Allow HTTP traffic to ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Health Check traffic to EC2 on port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# Security Group for EC2 Instances
# Only accepts traffic from the ALB (safer than exposing it to the internet).
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Allow traffic only from the ALB security group
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Accept only ALB traffic
  }

  # Allow all outbound traffic (required for instance updates, database, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# ----------------- LOAD BALANCER CONFIGURATION -----------------
# Create Application Load Balancer (ALB)
# Balances traffic between multiple EC2 instances

# Create Application Load Balancer (ALB)
resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_net.id, aws_subnet.public_net_2.id] # # Attach to Public Subnet, Use both subnets
  security_groups    = [aws_security_group.alb_sg.id] # Assign ALB Security Group
}


# Create ALB Listener for HTTP (Port 80)
# Listens on port 80 and forwards traffic to EC2 instances
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

# Create Target Group for ALB
resource "aws_lb_target_group" "instances" {
  name     = "web-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach EC2 Instance to Target Group
resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.example.id
  port             = 8080

  depends_on = [aws_instance.example]
}

# ----------------- EC2 INSTANCE -----------------
# Create EC2 Instance (Inside VPC)
# Creates an EC2 instance inside the public subnet
# Ensures it can receive traffic from ALB

resource "aws_instance" "example" {
  ami                         = "ami-0e1bed4f06a3b463d" # Ubuntu 22.04 LTS (x86_64)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_net.id # Use the Public Subnet
  security_groups             = [aws_security_group.web_sg.id]
  associate_public_ip_address = true # Ensure it has a public IP

  user_data = <<-EOF
              #!/bin/bash
              echo "Web Page Application Goes Here" > index.html
              nohup python3 -m http.server 8080 &
              EOF

  depends_on = [aws_lb_target_group.instances]

  tags = {
    Name = "WebServer"
  }
}

# output "load_balancer_dns" {
#   value = aws_lb.load_balancer.dns_name
#   description = "The DNS name of the Application Load Balancer"
# }
