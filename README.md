# terraform-aws-vpc-baseline

A production-shaped AWS VPC: public and private subnets across multiple availability zones, NAT with an explicit cost/availability toggle, flow logs, and a free S3 gateway endpoint.

I have rebuilt this VPC by hand for most projects I have worked on. This is that pattern written once, properly.

## Why another VPC module

Most VPC modules are either too thin to use in production or so configurable that reading them costs more than writing your own. This one makes a small number of opinionated decisions and exposes the two that actually vary between environments:

- **`single_nat_gateway`** — one NAT for the whole VPC instead of one per AZ. A NAT gateway is roughly \$32/month before data processing, so three AZs is ~\$96/month standing cost. That is worth paying in production, where losing one AZ should not cut outbound connectivity for everything. It is not worth paying in a development account that is idle overnight. The flag makes that trade-off explicit instead of hiding it in a diff.
- **`enable_flow_logs`** — on by default. The first time you need to answer "what talked to what at 02:00" and the logs are not there, you will not make that mistake again.

Private route tables are created per AZ regardless of NAT count, so flipping `single_nat_gateway` later changes routes rather than recreating subnets.

## Usage

```hcl
module "vpc" {
  source = "github.com/arunrajm91/terraform-aws-vpc-baseline"

  name        = "platform-prod"
  cidr_block  = "10.20.0.0/16"
  az_count    = 3
  environment = "prod"

  # Production: NAT per AZ
  single_nat_gateway = false

  tags = {
    Owner = "platform-team"
  }
}
```

Development, where the standing NAT cost is not justified:

```hcl
module "vpc" {
  source = "github.com/arunrajm91/terraform-aws-vpc-baseline"

  name               = "platform-dev"
  cidr_block         = "10.30.0.0/16"
  az_count           = 2
  environment        = "dev"
  single_nat_gateway = true
}
```

## Address plan

With the defaults (`/16` VPC, `subnet_newbits = 8`, `az_count = 3`) you get six `/24` subnets:

| Subnet | AZ | CIDR |
|---|---|---|
| public-a | a | 10.0.0.0/24 |
| public-b | b | 10.0.1.0/24 |
| public-c | c | 10.0.2.0/24 |
| private-a | a | 10.0.3.0/24 |
| private-b | b | 10.0.4.0/24 |
| private-c | c | 10.0.5.0/24 |

Public subnets take the first `az_count` blocks and private the next, so the plan stays predictable as AZs are added.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|:---:|
| name | Name prefix applied to every resource | `string` | — | yes |
| cidr_block | IPv4 CIDR for the VPC | `string` | `"10.0.0.0/16"` | no |
| az_count | Availability zones to spread across | `number` | `3` | no |
| subnet_newbits | Bits added to the VPC prefix when carving subnets | `number` | `8` | no |
| enable_nat_gateway | Create NAT gateways for private subnet egress | `bool` | `true` | no |
| single_nat_gateway | Share one NAT across all AZs (cost saving, lower availability) | `bool` | `false` | no |
| enable_flow_logs | Send VPC flow logs to CloudWatch | `bool` | `true` | no |
| flow_logs_retention_days | Flow log retention in days | `number` | `30` | no |
| enable_s3_endpoint | Create a gateway endpoint for S3 | `bool` | `true` | no |
| environment | Environment tag value | `string` | `"dev"` | no |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | Public subnet IDs, ordered by AZ |
| private_subnet_ids | Private subnet IDs, ordered by AZ |
| public_subnets_by_az | Map of AZ to public subnet ID |
| private_subnets_by_az | Map of AZ to private subnet ID |
| availability_zones | AZs the VPC spans |
| internet_gateway_id | ID of the internet gateway |
| nat_gateway_ids | NAT gateway IDs keyed by AZ |
| nat_public_ips | NAT public IPs — useful for third-party allowlisting |
| private_route_table_ids | Private route table IDs keyed by AZ |

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.5.0 |
| aws | >= 5.0 |

## Cost notes

The S3 gateway endpoint is free and removes S3 traffic from NAT data processing charges — on S3-heavy workloads it pays for the module on its own.

NAT gateways are the dominant cost here. With `single_nat_gateway = true` and `az_count = 3` you save roughly \$64/month at the price of AZ-independent egress.

## License

MIT
