output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = { for name, subnet in aws_subnet.public : name => subnet.id }
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = { for name, subnet in aws_subnet.private : name => subnet.id }
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = { for name, nat in aws_nat_gateway.this : name => nat.id }
}
