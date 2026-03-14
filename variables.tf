# variables.tf
# =============================================================================
# All input variables for the Terraform configuration.
# Defaults are set for the us-east-2 development environment.
# Override any of these by creating a terraform.tfvars file or passing
# -var flags at the command line.
# =============================================================================

variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name prefix for all resources. Used in tags and resource names."
  type        = string
  default     = "cicd-demo"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Name of the team or person who owns these resources (used in tags)"
  type        = string
  default     = "CamBlue"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be a valid private CIDR range."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet. Must be a subset of vpc_cidr."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free tier eligible."
  type        = string
  default     = "t3.micro"
}

