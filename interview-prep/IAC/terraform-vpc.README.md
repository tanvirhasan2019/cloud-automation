# Terraform VPC Module - Infrastructure as Code (IaC)

## Overview

This Terraform module creates a production-ready VPC (Virtual Private Cloud) with public and private subnets distributed across multiple Availability Zones. This is a common interview question and fundamental AWS infrastructure pattern.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  AZ-1a                │  AZ-1b                │  AZ-1c      │
│                       │                       │             │
│  Public Subnet        │  Public Subnet        │  Public...  │
│  10.0.1.0/24         │  10.0.2.0/24         │  10.0.3.0/24│
│  ┌─────────────┐     │  ┌─────────────┐     │             │
│  │   NAT GW    │     │  │   NAT GW    │     │             │
│  └─────────────┘     │  └─────────────┘     │             │
│                       │                       │             │
│  Private Subnet       │  Private Subnet       │  Private... │
│  10.0.101.0/24       │  10.0.102.0/24       │  10.0.103../24
│                       │                       │             │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. VPC (Virtual Private Cloud)
- **Purpose**: Isolated network environment in AWS
- **CIDR Block**: 10.0.0.0/16 (provides 65,536 IP addresses)
- **DNS Support**: Enabled for hostname resolution

### 2. Subnets
- **Public Subnets**: Direct internet access via Internet Gateway
- **Private Subnets**: Internet access via NAT Gateway (outbound only)
- **Multi-AZ**: Distributed across 3 Availability Zones for high availability

### 3. Internet Gateway (IGW)
- **Purpose**: Allows internet access for public subnets
- **Attachment**: Connected to VPC

### 4. NAT Gateways
- **Purpose**: Enable outbound internet access for private subnets
- **Placement**: One per public subnet for high availability
- **Cost Consideration**: NAT Gateways incur hourly charges

### 5. Route Tables
- **Public Route Table**: Routes 0.0.0.0/0 to Internet Gateway
- **Private Route Tables**: Route 0.0.0.0/0 to respective NAT Gateway

## Module Structure

```
terraform-vpc-module/
├── main.tf              # Main resource definitions
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── versions.tf         # Provider requirements
└── README.md           # This file
```

## Terraform Code

### main.tf
```hcl
# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 101}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-${count.index + 1}"
    Type = "Private"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? var.az_count : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-eip-${count.index + 1}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.az_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-${count.index + 1}"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? var.az_count : 1

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}
```

### variables.tf
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones"
  type        = number
  default     = 3
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "AZ count must be between 2 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}
```

### versions.tf
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## Usage Example

### Basic Usage
```hcl
module "vpc" {
  source = "./terraform-vpc-module"

  project_name = "my-app"
  vpc_cidr     = "10.0.0.0/16"
  az_count     = 3

  common_tags = {
    Environment = "production"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Use the outputs
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]

  tags = {
    Name = "web-server"
  }
}
```

### Cost-Optimized Usage (No NAT Gateway)
```hcl
module "vpc" {
  source = "./terraform-vpc-module"

  project_name       = "dev-environment"
  enable_nat_gateway = false
  az_count          = 2

  common_tags = {
    Environment = "development"
    CostCenter  = "engineering"
  }
}
```

## Interview Questions & Answers

### Q1: Why use multiple Availability Zones?
**Answer**: Multiple AZs provide high availability and fault tolerance. If one AZ fails, your application can continue running in other AZs. AWS recommends distributing resources across at least 2 AZs for production workloads.

### Q2: What's the difference between public and private subnets?
**Answer**: 
- **Public Subnets**: Have a route to the Internet Gateway (0.0.0.0/0 → IGW), resources get public IPs
- **Private Subnets**: No direct internet access, use NAT Gateway for outbound connections only

### Q3: Why use NAT Gateway instead of NAT Instance?
**Answer**:
- **Managed Service**: AWS handles availability and maintenance
- **Higher Bandwidth**: Up to 45 Gbps vs limited EC2 instance bandwidth
- **Better Availability**: Built-in redundancy within AZ
- **No Security Groups**: Uses NACLs only

### Q4: How would you reduce costs in this setup?
**Answer**:
- Use single NAT Gateway instead of one per AZ (reduces availability)
- Use NAT Instance instead of NAT Gateway for low-traffic environments
- Set `enable_nat_gateway = false` for development environments
- Use VPC Endpoints for AWS services to avoid NAT Gateway charges

### Q5: Explain the CIDR block strategy used here.
**Answer**:
- **VPC CIDR**: 10.0.0.0/16 (65,536 IPs)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 (256 IPs each)
- **Private Subnets**: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24 (256 IPs each)
- Leaves room for additional subnets (database, cache, etc.)

### Q6: What are Terraform best practices demonstrated here?
**Answer**:
- **Variables**: Parameterized configuration
- **Outputs**: Expose important resource IDs
- **Data Sources**: Dynamic AZ discovery
- **Resource Dependencies**: Proper depends_on usage
- **Tagging Strategy**: Consistent resource tagging
- **Validation**: Input validation for variables

## Security Considerations

1. **Network ACLs**: Consider implementing NACLs for additional security
2. **Security Groups**: Plan security group strategy for resources
3. **VPC Flow Logs**: Enable for network monitoring and troubleshooting
4. **Route Table Security**: Ensure only necessary routes exist

## Cost Optimization

- **NAT Gateway**: ~$45/month per gateway + data processing charges
- **EIP**: ~$3.65/month if not attached to running instance
- **VPC**: No charge for VPC itself, only associated resources

## Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="project_name=my-vpc"

# Apply the configuration
terraform apply -var="project_name=my-vpc"

# Destroy when no longer needed
terraform destroy
```

## Advanced Production Extensions

### Extended Module Structure
```
terraform-vpc-module/
├── main.tf              # Core VPC resources
├── advanced.tf          # Advanced production components
├── variables.tf         # All input variables
├── outputs.tf          # All output values
├── versions.tf         # Provider requirements
└── README.md           # This documentation
```

### advanced.tf - Production Components
```hcl
# VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-log"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = var.enable_database_subnets ? var.az_count : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 201}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-database-${count.index + 1}"
    Type = "Database"
  })
}

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.enable_database_subnets ? 1 : 0

  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# Cache Subnets
resource "aws_subnet" "cache" {
  count = var.enable_cache_subnets ? var.az_count : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 251}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cache-${count.index + 1}"
    Type = "Cache"
  })
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  count = var.enable_cache_subnets ? 1 : 0

  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = aws_subnet.cache[*].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cache-subnet-group"
  })
}

# Database Route Table
resource "aws_route_table" "database" {
  count = var.enable_database_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-database-rt"
  })
}

# Database Route Table Associations
resource "aws_route_table_association" "database" {
  count = var.enable_database_subnets ? var.az_count : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# Cache Route Table Associations (use database route table)
resource "aws_route_table_association" "cache" {
  count = var.enable_cache_subnets ? var.az_count : 0

  subnet_id      = aws_subnet.cache[count.index].id
  route_table_id = var.enable_database_subnets ? aws_route_table.database[0].id : aws_route_table.private[0].id
}

# VPC Endpoints for AWS Services
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    var.enable_database_subnets ? aws_route_table.database[*].id : []
  )

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    var.enable_database_subnets ? aws_route_table.database[*].id : []
  )

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dynamodb-endpoint"
  })
}

# Interface VPC Endpoints (with security group)
resource "aws_security_group" "vpc_endpoints" {
  count = var.enable_vpc_endpoints ? 1 : 0

  name_prefix = "${var.project_name}-vpc-endpoints-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-endpoints-sg"
  })
}

locals {
  interface_endpoints = var.enable_vpc_endpoints ? var.vpc_interface_endpoints : []
}

resource "aws_vpc_endpoint" "interface" {
  count = length(local.interface_endpoints)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${local.interface_endpoints[count.index]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${local.interface_endpoints[count.index]}-endpoint"
  })
}

# Network ACLs
resource "aws_network_acl" "public" {
  count = var.enable_network_acls ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Allow HTTP/HTTPS inbound
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow SSH from specific CIDR
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = var.ssh_cidr_block
    from_port  = 22
    to_port    = 22
  }

  # Allow ephemeral ports for responses
  ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-nacl"
  })
}

resource "aws_network_acl" "private" {
  count = var.enable_network_acls ? 1 : 0

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Allow traffic from VPC
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow ephemeral ports for internet responses
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-nacl"
  })
}

# VPN Gateway (for hybrid connectivity)
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id          = aws_vpc.main.id
  amazon_side_asn = var.vpn_gateway_asn

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpn-gateway"
  })
}

# Customer Gateway (example configuration)
resource "aws_customer_gateway" "main" {
  count = var.enable_vpn_gateway && var.customer_gateway_ip != "" ? 1 : 0

  bgp_asn    = var.customer_gateway_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-customer-gateway"
  })
}

# VPN Connection
resource "aws_vpn_connection" "main" {
  count = var.enable_vpn_gateway && var.customer_gateway_ip != "" ? 1 : 0

  vpn_gateway_id      = aws_vpn_gateway.main[0].id
  customer_gateway_id = aws_customer_gateway.main[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpn-connection"
  })
}

# Transit Gateway (for multi-VPC connectivity)
resource "aws_ec2_transit_gateway" "main" {
  count = var.enable_transit_gateway ? 1 : 0

  description                     = "${var.project_name} Transit Gateway"
  amazon_side_asn                 = var.transit_gateway_asn
  auto_accept_shared_attachments  = "enable"
  auto_accept_shared_associations = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-tgw"
  })
}

# Transit Gateway VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  count = var.enable_transit_gateway ? 1 : 0

  subnet_ids         = aws_subnet.private[*].id
  transit_gateway_id = aws_ec2_transit_gateway.main[0].id
  vpc_id             = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-tgw-attachment"
  })
}

# Data sources
data "aws_region" "current" {}
```

### Extended variables.tf (Additional Variables)
```hcl
# Advanced Features Toggle Variables
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention period in days"
  type        = number
  default     = 14
}

variable "enable_database_subnets" {
  description = "Enable dedicated database subnets"
  type        = bool
  default     = false
}

variable "enable_cache_subnets" {
  description = "Enable dedicated cache subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints for AWS services"
  type        = bool
  default     = false
}

variable "vpc_interface_endpoints" {
  description = "List of AWS services for interface VPC endpoints"
  type        = list(string)
  default     = ["ec2", "ssm", "ssmmessages", "ec2messages", "logs"]
}

variable "enable_network_acls" {
  description = "Enable custom Network ACLs"
  type        = bool
  default     = false
}

variable "ssh_cidr_block" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "10.0.0.0/8"
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway for hybrid connectivity"
  type        = bool
  default     = false
}

variable "vpn_gateway_asn" {
  description = "ASN for the Amazon side of the VPN gateway"
  type        = number
  default     = 64512
}

variable "customer_gateway_ip" {
  description = "IP address of the customer gateway"
  type        = string
  default     = ""
}

variable "customer_gateway_asn" {
  description = "ASN for the customer gateway"
  type        = number
  default     = 65000
}

variable "enable_transit_gateway" {
  description = "Enable Transit Gateway for multi-VPC connectivity"
  type        = bool
  default     = false
}

variable "transit_gateway_asn" {
  description = "ASN for the Transit Gateway"
  type        = number
  default     = 64512
}
```

### Extended outputs.tf (Additional Outputs)
```hcl
# Advanced Component Outputs
output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = var.enable_database_subnets ? aws_subnet.database[*].id : []
}

output "cache_subnet_ids" {
  description = "IDs of the cache subnets"
  value       = var.enable_cache_subnets ? aws_subnet.cache[*].id : []
}

output "db_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = var.enable_database_subnets ? aws_db_subnet_group.main[0].name : null
}

output "cache_subnet_group_name" {
  description = "Name of the cache subnet group"
  value       = var.enable_cache_subnets ? aws_elasticache_subnet_group.main[0].name : null
}

output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.vpc[0].id : null
}

output "vpc_endpoints" {
  description = "VPC Endpoint IDs and DNS names"
  value = var.enable_vpc_endpoints ? {
    s3_id       = aws_vpc_endpoint.s3[0].id
    dynamodb_id = aws_vpc_endpoint.dynamodb[0].id
    interface_endpoints = {
      for idx, endpoint in local.interface_endpoints :
      endpoint => {
        id        = aws_vpc_endpoint.interface[idx].id
        dns_names = aws_vpc_endpoint.interface[idx].dns_entry[*].dns_name
      }
    }
  } : {}
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = var.enable_transit_gateway ? aws_ec2_transit_gateway.main[0].id : null
}

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = var.enable_vpn_gateway ? aws_vpn_gateway.main[0].id : null
}

output "vpn_connection_id" {
  description = "ID of the VPN Connection"
  value       = var.enable_vpn_gateway && var.customer_gateway_ip != "" ? aws_vpn_connection.main[0].id : null
}
```

## Advanced Usage Examples

### Full Production Setup
```hcl
module "production_vpc" {
  source = "./terraform-vpc-module"

  project_name = "production-app"
  vpc_cidr     = "10.0.0.0/16"
  az_count     = 3

  # Advanced Features
  enable_flow_logs         = true
  enable_database_subnets  = true
  enable_cache_subnets     = true
  enable_vpc_endpoints     = true
  enable_network_acls      = true
  enable_transit_gateway   = true

  # VPC Endpoints
  vpc_interface_endpoints = [
    "ec2", "ssm", "ssmmessages", "ec2messages", 
    "logs", "monitoring", "s3", "kms"
  ]

  # Security
  ssh_cidr_block = "10.0.0.0/8"

  common_tags = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "engineering"
    Compliance  = "required"
  }
}

# Use database subnets for RDS
resource "aws_db_instance" "main" {
  identifier             = "production-db"
  engine                 = "postgres"
  instance_class         = "db.r5.large"
  allocated_storage      = 100
  db_subnet_group_name   = module.production_vpc.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  # ... other RDS configuration
}

# Use cache subnets for ElastiCache
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "production-cache"
  engine               = "redis"
  node_type            = "cache.r5.large"
  subnet_group_name    = module.production_vpc.cache_subnet_group_name
  security_group_ids   = [aws_security_group.cache.id]
  
  # ... other ElastiCache configuration
}
```

### Hybrid Cloud Setup
```hcl
module "hybrid_vpc" {
  source = "./terraform-vpc-module"

  project_name = "hybrid-environment"
  
  # Enable hybrid connectivity
  enable_vpn_gateway    = true
  customer_gateway_ip   = "203.0.113.1"  # Your on-premises public IP
  customer_gateway_asn  = 65000
  vpn_gateway_asn      = 64512

  # Enhanced monitoring and security
  enable_flow_logs    = true
  enable_network_acls = true
  ssh_cidr_block     = "192.168.0.0/16"  # On-premises network

  common_tags = {
    Environment = "hybrid"
    Connectivity = "vpn"
  }
}
```

### Multi-VPC Enterprise Setup
```hcl
# Hub VPC with Transit Gateway
module "hub_vpc" {
  source = "./terraform-vpc-module"

  project_name = "hub"
  enable_transit_gateway = true
  transit_gateway_asn   = 64512
  
  common_tags = {
    Role = "hub"
    Environment = "shared"
  }
}

# Spoke VPCs
module "prod_vpc" {
  source = "./terraform-vpc-module"

  project_name = "production"
  vpc_cidr     = "10.1.0.0/16"
  
  common_tags = {
    Role = "spoke"
    Environment = "production"
  }
}

# Connect spoke to hub via Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "prod_to_hub" {
  subnet_ids         = module.prod_vpc.private_subnet_ids
  transit_gateway_id = module.hub_vpc.transit_gateway_id
  vpc_id            = module.prod_vpc.vpc_id
}
```

## Advanced Interview Questions & Answers

### Q7: Explain VPC Flow Logs and their use cases.
**Answer**: VPC Flow Logs capture network traffic metadata for monitoring, troubleshooting, and security analysis. Use cases include:
- **Security**: Detect unusual traffic patterns, potential attacks
- **Troubleshooting**: Identify connectivity issues, bandwidth bottlenecks  
- **Compliance**: Network audit trails for regulatory requirements
- **Cost Optimization**: Identify high-traffic patterns for optimization

### Q8: When would you use VPC Endpoints vs NAT Gateway?
**Answer**:
- **VPC Endpoints**: For AWS service traffic (S3, DynamoDB, EC2 API)
  - Cost: Only pay for usage, no hourly charge
  - Security: Traffic stays within AWS network
  - Performance: Lower latency, higher throughput
- **NAT Gateway**: For general internet access
  - Cost: ~$45/month + data processing
  - Use: When private resources need internet access

### Q9: Explain the subnet tier strategy (public/private/database/cache).
**Answer**:
- **Public Subnets**: Load balancers, bastion hosts, NAT gateways
- **Private Subnets**: Application servers, microservices
- **Database Subnets**: RDS instances, isolated with no internet route
- **Cache Subnets**: ElastiCache, Redis clusters, separate for performance tuning
This provides defense in depth and follows the principle of least privilege.

### Q10: How does Transit Gateway differ from VPC Peering?
**Answer**:
- **Transit Gateway**: Hub-and-spoke model, scales to thousands of VPCs, supports on-premises connectivity, route management
- **VPC Peering**: Point-to-point connections, doesn't scale well (N*(N-1)/2 connections), no transitive routing
- **Use Transit Gateway** for: Multi-VPC architectures, hybrid connectivity, centralized routing

### Q11: What are Network ACLs vs Security Groups?
**Answer**:
- **Network ACLs**: Subnet-level, stateless, numbered rules, allow/deny
- **Security Groups**: Instance-level, stateful, allow rules only
- **Best Practice**: Use Security Groups primarily, NACLs for additional subnet-level controls

### Q12: How would you design for disaster recovery?
**Answer**:
- **Multi-AZ**: Distribute resources across 3+ AZs
- **Multi-Region**: Critical workloads in multiple regions
- **Transit Gateway**: For cross-region connectivity
- **VPN/DX**: Hybrid connectivity for failback scenarios
- **Automation**: Infrastructure as Code for rapid deployment

## Security Best Practices

1. **Defense in Depth**: Multiple security layers (NACLs + Security Groups)
2. **Least Privilege**: Minimal required access only
3. **Network Segmentation**: Separate tiers for different functions
4. **Monitoring**: VPC Flow Logs, CloudTrail, GuardDuty
5. **Encryption**: In-transit and at-rest encryption
6. **Private Connectivity**: VPC Endpoints for AWS services

## Cost Optimization Strategies

1. **VPC Endpoints**: Reduce NAT Gateway data charges for AWS services
2. **Single NAT Gateway**: For non-critical environments
3. **Reserved Capacity**: For predictable workloads
4. **Right-sizing**: Monitor and optimize instance sizes
5. **Lifecycle Management**: Automate resource cleanup

This advanced module demonstrates enterprise-level AWS networking patterns and is perfect for senior-level infrastructure interviews. It covers all major networking concepts while maintaining production-ready code quality.
