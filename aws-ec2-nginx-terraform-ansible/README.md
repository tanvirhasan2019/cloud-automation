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
