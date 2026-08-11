terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

# Production shape: three AZs, NAT per AZ, flow logs on.
module "vpc_prod" {
  source = "../../"

  name        = "example-prod"
  cidr_block  = "10.20.0.0/16"
  az_count    = 3
  environment = "prod"

  single_nat_gateway = false
  enable_flow_logs   = true

  tags = {
    Owner   = "platform-team"
    Project = "example"
  }
}

# Development shape: two AZs, shared NAT, shorter log retention.
module "vpc_dev" {
  source = "../../"

  name        = "example-dev"
  cidr_block  = "10.30.0.0/16"
  az_count    = 2
  environment = "dev"

  single_nat_gateway       = true
  flow_logs_retention_days = 7

  tags = {
    Owner   = "platform-team"
    Project = "example"
  }
}

output "prod_vpc_id" {
  value = module.vpc_prod.vpc_id
}

output "prod_private_subnets" {
  value = module.vpc_prod.private_subnet_ids
}

output "prod_nat_ips" {
  description = "Allowlist these with third parties."
  value       = module.vpc_prod.nat_public_ips
}

output "dev_vpc_id" {
  value = module.vpc_dev.vpc_id
}
