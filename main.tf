# main.tf
# =============================================================================
# Provider Configuration
# =============================================================================
# The AWS provider tells Terraform which cloud to talk to and which region to
# use by default. The region is supplied via a variable so it can be overridden
# for different environments without editing this file.
# =============================================================================

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # These default tags are applied to every resource this provider creates.
  # This is 2026 best practice — every resource is tagged for cost tracking,
  # environment identification, and ownership.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      Repository  = "https://github.com/CamBlue/terraform-cicd"
    }
  }
}

# =============================================================================
# VPC
# =============================================================================
# A VPC (Virtual Private Cloud) is your isolated network in AWS. Everything
# we create lives inside this VPC. The CIDR block 10.0.0.0/16 gives us
# 65,536 private IP addresses to work with.
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# =============================================================================
# Internet Gateway
# =============================================================================
# An Internet Gateway (IGW) is what allows resources in a public subnet to
# send and receive traffic from the internet. Without it, even a public subnet
# is isolated from the internet.
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# =============================================================================
# Public Subnet
# =============================================================================
# A subnet is a range of IPs within the VPC. This is a "public" subnet because
# we will attach a route table that routes internet traffic through the IGW.
# We place it in the first AZ of our region.
# =============================================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }
}

# =============================================================================
# Route Table
# =============================================================================
# The route table defines where traffic goes. We create a route that sends all
# internet-bound traffic (0.0.0.0/0) through the Internet Gateway.
# =============================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate the route table with our public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# Security Group
# =============================================================================
# A security group is a virtual firewall for your EC2 instance. It controls
# inbound and outbound traffic. We allow:
#   - Inbound SSH (port 22) from anywhere — for demo purposes only. In
#     production, restrict this to your IP address or a VPN CIDR.
#   - Inbound HTTP (port 80) from anywhere — so we can verify the instance
#     is reachable.
#   - All outbound traffic — so the instance can reach the internet for
#     package updates etc.
# =============================================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for the web EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
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
    Name = "${var.project_name}-web-sg"
  }
}

# =============================================================================
# Data Source: Latest Amazon Linux 2023 AMI
# =============================================================================
# Instead of hardcoding an AMI ID (which differs by region and goes stale),
# we use a data source to dynamically find the latest Amazon Linux 2023 AMI
# for our region. This keeps the config portable and always current.
# =============================================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =============================================================================
# EC2 Instance
# =============================================================================
# The actual virtual machine. We use a t3.micro which is free tier eligible.
# The user_data script runs on first boot and installs a simple web server
# so we can verify the instance is running by hitting its public IP.
# =============================================================================

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # This user_data script installs httpd (Apache) and starts it.
  # It runs exactly once when the instance is first launched.
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Deployed via Terraform CI/CD Pipeline</h1>" > /var/www/html/index.html
    echo "<p>Project: ${var.project_name}</p>" >> /var/www/html/index.html
    echo "<p>Environment: ${var.environment}</p>" >> /var/www/html/index.html
  EOF

  # The root EBS volume — 20 GB, GP3 is the modern SSD type, encrypted
  # for security best practice.
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
