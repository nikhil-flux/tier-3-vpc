# =============================================================================
# AWS REGION
# =============================================================================
variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1" 
  
  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|me|af)-(north|south|east|west|central|northeast|southeast)-[1-3]$", var.aws_region))
    error_message = "Must be a valid AWS region."
  }
}

# =============================================================================
# VPC CIDR BLOCK
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC (must be /16 or larger)"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# =============================================================================
# ENVIRONMENT NAME
# =============================================================================
variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# =============================================================================
# AVAILABILITY ZONES
# =============================================================================
variable "availability_zones" {
  description = "List of availability zones to deploy subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}