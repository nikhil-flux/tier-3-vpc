# =============================================================================
# VPC OUTPUTS
# =============================================================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# =============================================================================
# SUBNET OUTPUTS
# =============================================================================
output "public_subnet_ids" {
  description = "List of public subnet IDs (Web Tier)"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs (App Tier)"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs (DB Tier)"
  value       = aws_subnet.private_db[*].id
}

# =============================================================================
# NETWORKING OUTPUTS
# =============================================================================
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_id" {
  description = "The ID of the private application route table"
  value       = aws_route_table.private_app.id
}

output "private_db_route_table_id" {
  description = "The ID of the private database route table"
  value       = aws_route_table.private_db.id
}

# =============================================================================
# SECURITY GROUP OUTPUTS
# =============================================================================
output "web_tier_security_group_id" {
  description = "The ID of the web tier security group"
  value       = aws_security_group.web_tier.id
}

output "app_tier_security_group_id" {
  description = "The ID of the application tier security group"
  value       = aws_security_group.app_tier.id
}

output "db_tier_security_group_id" {
  description = "The ID of the database tier security group"
  value       = aws_security_group.db_tier.id
}