# Terraform VPC Module - Infrastructure as Code (IaC)

## Overview

This Terraform module creates a production-ready VPC (Virtual Private 
Cloud) with public and private subnets distributed across multiple 
Availability Zones. This is a common interview question and fundamental 
AWS infrastructure pattern.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  AZ-1a                │  AZ-1b                │  AZ-1c      │
│                       │                       │             │
│  Public Subnet        │  Public Subnet        │  Public...  │
│  10.0.1.0/24         │  10.0.2.0/24         │  10.0.3.0/24│
│  ┌─────────────┐     │  ┌─────────────┐     
│             │
│  │   NAT GW    │     │  │   NAT GW    │     │             │
│  └─────────────┘     │  └─────────────┘     
│             │
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
- **Multi-AZ**: Distributed across 3 Availability Zones for high 
availability

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
  availability_zone       = 
data.aws_availability_zones.available.names[count.index]
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
  availability_zone = 
data.aws_availability_zones.available.names[count.index]

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
  route_table_id = var.enable_nat_gateway ? 
aws_route_table.private[count.index].id : aws_route_table.private[0].id
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
  value       = slice(data.aws_availability_zones.available.names, 0, 
var.az_count)
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
**Answer**: Multiple AZs provide high availability and fault tolerance. If 
one AZ fails, your application can continue running in other AZs. AWS 
recommends distributing resources across at least 2 AZs for production 
workloads.

### Q2: What's the difference between public and private subnets?
**Answer**: 
- **Public Subnets**: Have a route to the Internet Gateway (0.0.0.0/0 → 
IGW), resources get public IPs
- **Private Subnets**: No direct internet access, use NAT Gateway for 
outbound connections only

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
- **Private Subnets**: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24 (256 
IPs each)
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

## Advanced Extensions

Consider adding these components for production:
- VPC Flow Logs
- VPC Endpoints for AWS services
- Network ACLs
- Additional subnet tiers (database, cache)
- Transit Gateway integration
- VPN Gateway for hybrid connectivity

This module provides a solid foundation for AWS networking and 
demonstrates key Infrastructure as Code principles that are commonly 
discussed in DevOps and Cloud Engineering interviews.
