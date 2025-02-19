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

## Prerequisites
```bash
AWS Account
Terraform (>= 1.0.0)
Ansible (>= 2.9)
AWS CLI
```

## AWS Credentials Setup
Configure AWS credentials using one of the following methods:

## AWS CLI Configuration:
```bash
aws configure
```
