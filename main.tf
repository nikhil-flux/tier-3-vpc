# PROVIDER CONFIGURATION

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Three-Tier-VPC"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# VPC RESOURCE

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.environment}-vpc"
  }
}

# INTERNET GATEWAY

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.environment}-igw"
  }
}

# PUBLIC SUBNETS (WEB TIER)

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Tier = "web"
  }
}

# PRIVATE SUBNETS - APPLICATION TIER

resource "aws_subnet" "private_app" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-app-subnet-${count.index + 1}"
    Tier = "application"
  }
}

# PRIVATE SUBNETS - DATABASE TIER

resource "aws_subnet" "private_db" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 6)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-db-subnet-${count.index + 1}"
    Tier = "database"
  }
}

# ELASTIC IPs FOR NAT GATEWAYS

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  
  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  }
}

# NAT GATEWAYS

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name = "${var.environment}-nat-gw-${count.index + 1}"
  }
  
  depends_on = [aws_internet_gateway.main]
}

# ROUTE TABLES

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# Private Application Route Table
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }
  
  tags = {
    Name = "${var.environment}-private-app-rt"
  }
}

# Private Database Route Table (No internet access)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.environment}-private-db-rt"
  }
}

# ROUTE TABLE ASSOCIATIONS

# Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Application Subnets
resource "aws_route_table_association" "private_app" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# Private Database Subnets
resource "aws_route_table_association" "private_db" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}

# SECURITY GROUPS

# Web Tier Security Group
resource "aws_security_group" "web_tier" {
  name        = "${var.environment}-web-sg"
  description = "Security group for web tier - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.environment}-web-sg"
  }
}

# Application Tier Security Group
resource "aws_security_group" "app_tier" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application tier - allows traffic from web tier only"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "Application port from web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }
  
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-app-sg"
  }
}

# Database Tier Security Group
resource "aws_security_group" "db_tier" {
  name        = "${var.environment}-db-sg"
  description = "Security group for database tier - allows MySQL from app tier only"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "MySQL from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }
  
  tags = {
    Name = "${var.environment}-db-sg"
  }
}