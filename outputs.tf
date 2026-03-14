# outputs.tf
# =============================================================================
# Output values that are printed after terraform apply completes.
# These are also accessible to other Terraform configurations that reference
# this one as a module, and they appear in the GitHub Actions job summary.
# =============================================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "The ID of the web security group"
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "The public DNS hostname of the EC2 instance"
  value       = aws_instance.web.public_dns
}

output "web_url" {
  description = "URL to access the web server running on the EC2 instance"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ami_id" {
  description = "The AMI ID that was used to launch the EC2 instance"
  value       = data.aws_ami.amazon_linux_2023.id
}
