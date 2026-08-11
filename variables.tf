variable "name" {
  description = "Name prefix applied to every resource created by this module."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must be lowercase alphanumeric with hyphens only."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC. A /16 gives comfortable room for growth."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across. Three is the practical minimum for production."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "az_count must be between 1 and 6."
  }
}

variable "subnet_newbits" {
  description = "Bits to add to the VPC prefix when carving subnets. With a /16 VPC, 8 produces /24 subnets."
  type        = number
  default     = 8
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways so private subnets can reach the internet. Disable for fully isolated VPCs."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = <<-EOT
    Route all private subnets through one NAT gateway instead of one per AZ.

    This is a deliberate cost/availability trade-off. A NAT gateway costs roughly
    \$32/month plus data processing, so three AZs means ~\$96/month before traffic.
    Set true for development and staging; leave false for production, where losing
    a single AZ should not remove outbound connectivity for the whole VPC.
  EOT
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch Logs. Worth the cost in any environment you may need to debug or audit."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention for flow logs, in days."
  type        = number
  default     = 30
}

variable "enable_s3_endpoint" {
  description = "Create a gateway VPC endpoint for S3. Free, and removes S3 traffic from the NAT gateway data charge."
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name, applied as a tag (e.g. prod, staging, dev)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
