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

VPC with public subnet
Internet Gateway
Route Table
Security Group (ports 22, 80)
EC2 instance (t2.micro)
SSH Key Pair

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
