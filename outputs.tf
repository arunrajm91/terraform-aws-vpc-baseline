output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs, ordered by availability zone."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, ordered by availability zone."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "public_subnets_by_az" {
  description = "Map of availability zone to public subnet ID."
  value       = { for az, subnet in aws_subnet.public : az => subnet.id }
}

output "private_subnets_by_az" {
  description = "Map of availability zone to private subnet ID."
  value       = { for az, subnet in aws_subnet.private : az => subnet.id }
}

output "availability_zones" {
  description = "Availability zones the VPC spans."
  value       = local.azs
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs, keyed by availability zone. Empty when NAT is disabled."
  value       = { for az, ngw in aws_nat_gateway.this : az => ngw.id }
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways. Useful for allowlisting outbound traffic with third parties."
  value       = [for eip in aws_eip.nat : eip.public_ip]
}

output "private_route_table_ids" {
  description = "Private route table IDs, keyed by availability zone."
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}
