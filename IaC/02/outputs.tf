output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.frodo.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = { for name, subnet in aws_subnet.public : name => subnet.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = { for name, subnet in aws_subnet.private : name => subnet.id }
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.frodo.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.frodo.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance."
  value       = aws_instance.frodo.public_ip
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 instance."
  value       = aws_instance.frodo.private_ip
}

output "ssh_private_key_path" {
  description = "Path where the generated SSH private key is saved."
  value       = local.ssh_private_key_path_expanded
}

output "ssh_command" {
  description = "SSH command for connecting to the EC2 instance."
  value       = "ssh -i ${local.ssh_private_key_path_expanded} ec2-user@${aws_instance.frodo.public_ip}"
}
