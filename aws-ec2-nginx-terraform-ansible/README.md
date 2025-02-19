# AWS EC2 Nginx Deployment with Terraform and Ansible
This project automates the deployment of an Nginx web server on AWS EC2 using Terraform for infrastructure provisioning and Ansible for configuration management.

## Project Structure
```plaintext
├── README.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── ansible/
    ├── inventory/
    │   └── hosts.ini
    ├── roles/
    │   └── nginx/
    │       ├── tasks/
    │       │   └── main.yml
    │       └── templates/
    │           └── index.html.j2
    └── playbook.yml
```

## Prerequisites
```
AWS Account
Terraform (>= 1.0.0)
Ansible (>= 2.9)
AWS CLI
```

## AWS Credentials Setup
Configure AWS credentials using one of the following methods:

## AWS CLI Configuration:
```
aws configure
```

## Environment Variables:
```
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_REGION="us-west-2"
```

## Infrastructure Components
- VPC with public subnet
- Internet Gateway
- Route Table
- Security Group (ports 22, 80)
- EC2 instance (t2.micro)
- SSH Key Pair

### Installation & Deployment

1. Clone the repository:
```
git clone <repository-url>
cd <project-directory>
```
2. Initialize Terraform:
```
cd terraform
terraform init
```
3. Review and apply Terraform configuration:
```
terraform plan
terraform apply
```
4. Run Ansible playbook:
```
cd ../ansible
ansible-playbook -i inventory/hosts.ini playbook.yml
```

## Infrastructure Details
### VPC Configuration
- CIDR Block: 10.0.0.0/16
- Public Subnet: 10.0.1.0/24
- Region: us-west-2 (default, configurable)

### EC2 Instance
- Type: t2.micro
- OS: Ubuntu 22.04 LTS
- Volume: 8GB GP3
- Auto-assigned public IP: Yes

### Security Group Rules
Inbound:
- Port 80 (HTTP)
- Port 22 (SSH)

Outbound:
- All traffic

### Nginx Configuration
The Ansible playbook:

1. Updates system packages
2. Installs Nginx
3. Deploys custom index.html
4. Ensures Nginx service is running

## Accessing the Web Server
After deployment:

1. Get the public IP:
```
cd terraform
terraform output instance_public_ip
```
2. Access the website:
```
http://<instance_public_ip>
```

## SSH Access
The SSH private key is automatically generated and saved as terraform-web-key.pem in the terraform directory.
To connect:
```
ssh -i terraform/terraform-web-key.pem ubuntu@<instance_public_ip>
```

## Clean Up
To destroy the infrastructure:
```
cd terraform
terraform destroy
```

## Security Considerations

1. Production Modifications:
    - Restrict SSH access to specific IP ranges
    - Implement SSL/TLS
    - Use private subnets with NAT Gateway
    - Enable VPC flow logs
    - Implement proper IAM roles


2. Key Management:
    - Secure the generated SSH key
    - Consider using AWS Secrets Manager
    - Rotate keys regularly
  
## Customization
### Terraform Variables
Modify terraform.tfvars to customize:
- AWS region
- AMI ID
- Instance type
- Key pair name

### Nginx Configuration
Modify Ansible templates in:
```
ansible/roles/nginx/templates/index.html.j2
```

## Troubleshooting

1. SSH Connection Issues:
    - Verify security group rules
    - Check key permissions (should be 400)
    - Ensure proper key path in Ansible inventory

2. Nginx Access Issues:
    - Verify security group allows port 80
    - Check Nginx service status
    - Review instance public IP

