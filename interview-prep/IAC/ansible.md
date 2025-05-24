# Ansible Interview Preparation Guide

## Table of Contents
1. [Basic Concepts](#basic-concepts)
2. [Architecture & Components](#architecture--components)
3. [Playbooks & Tasks](#playbooks--tasks)
4. [Inventory Management](#inventory-management)
5. [Modules & Plugins](#modules--plugins)
6. [Variables & Facts](#variables--facts)
7. [Roles & Collections](#roles--collections)
8. [Error Handling & Debugging](#error-handling--debugging)
9. [Security & Best Practices](#security--best-practices)
10. [Advanced Topics](#advanced-topics)
11. [Practical Scenarios](#practical-scenarios)

---

## Basic Concepts

### Q1: What is Ansible and what are its key features?
**Answer:** Ansible is an open-source automation tool used for configuration management, application deployment, and task automation. Key features include:
- **Agentless**: No need to install agents on target machines
- **Idempotent**: Operations can be run multiple times without changing results
- **YAML-based**: Uses human-readable YAML syntax
- **Push-based**: Control node pushes configurations to managed nodes
- **Cross-platform**: Works on Linux, Windows, and network devices
- **Extensive module library**: 3000+ built-in modules

### Q2: How does Ansible work?
**Answer:** Ansible works by:
1. Reading inventory files to identify target hosts
2. Connecting to hosts via SSH (Linux) or WinRM (Windows)
3. Copying and executing Python modules on target hosts
4. Returning results to the control node
5. Cleaning up temporary files on target hosts

### Q3: What is the difference between Ansible and other configuration management tools?
**Answer:**
- **vs Puppet/Chef**: Ansible is agentless and uses push model; Puppet/Chef require agents and use pull model
- **vs SaltStack**: Both are agentless, but Salt uses ZeroMQ messaging while Ansible uses SSH
- **vs Terraform**: Ansible focuses on configuration management; Terraform focuses on infrastructure provisioning
- **Learning curve**: Ansible has gentler learning curve due to YAML syntax

---

## Architecture & Components

### Q4: Explain Ansible architecture and its components.
**Answer:** Ansible architecture consists of:

**Control Node:**
- Machine where Ansible is installed
- Executes playbooks and ad-hoc commands
- Maintains inventory and configuration files

**Managed Nodes:**
- Target machines managed by Ansible
- No Ansible software required
- Accessed via SSH or WinRM

**Key Components:**
- **Inventory**: List of managed nodes
- **Modules**: Units of work executed on nodes
- **Playbooks**: YAML files containing automation tasks
- **Plugins**: Extend Ansible functionality
- **API**: Programmatic access to Ansible

### Q5: What is an Ansible Control Node?
**Answer:** The Ansible Control Node is:
- The machine where Ansible is installed and run from
- Can be any machine with Python 2.7+ or Python 3.5+
- Cannot be a Windows machine (Windows can only be managed nodes)
- Stores inventory files, playbooks, and configuration
- Establishes connections to managed nodes

---

## Playbooks & Tasks

### Q6: What is an Ansible Playbook?
**Answer:** An Ansible Playbook is:
- A YAML file containing a series of plays
- Each play targets specific hosts and contains tasks
- Tasks are executed in order on specified hosts
- Can include variables, handlers, and conditional logic

**Example structure:**
```yaml
---
- name: Web server setup
  hosts: webservers
  become: yes
  tasks:
    - name: Install Apache
      yum:
        name: httpd
        state: present
    - name: Start Apache
      service:
        name: httpd
        state: started
```

### Q7: What is the difference between a Play and a Task?
**Answer:**
- **Play**: A section of a playbook that maps a group of tasks to a set of hosts
- **Task**: Individual unit of work within a play that calls an Ansible module

**Example:**
```yaml
- name: This is a PLAY
  hosts: webservers
  tasks:
    - name: This is a TASK
      yum:
        name: httpd
        state: present
```

### Q8: How do you run an Ansible Playbook?
**Answer:** Use the `ansible-playbook` command:
```bash
# Basic execution
ansible-playbook playbook.yml

# With specific inventory
ansible-playbook -i inventory.ini playbook.yml

# With extra variables
ansible-playbook playbook.yml --extra-vars "var1=value1"

# Dry run (check mode)
ansible-playbook playbook.yml --check

# Verbose output
ansible-playbook playbook.yml -v
```

---

## Inventory Management

### Q9: What is Ansible Inventory?
**Answer:** Ansible Inventory is:
- A file or script that defines the hosts Ansible manages
- Can be static (INI/YAML files) or dynamic (scripts/plugins)
- Groups hosts for easier management
- Can include host variables and group variables

**Static Inventory Example (INI format):**
```ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com ansible_user=admin
db2.example.com ansible_port=2222

[production:children]
webservers
databases
```

### Q10: What is Dynamic Inventory?
**Answer:** Dynamic Inventory:
- Automatically discovers and groups hosts from external sources
- Uses scripts or plugins to fetch host information
- Common sources: AWS EC2, Azure, GCP, VMware, etc.
- Updates automatically when infrastructure changes

**Example AWS EC2 dynamic inventory:**
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
keyed_groups:
  - key: tags
    prefix: tag
  - key: instance_type
    prefix: type
```

### Q11: How do you define host variables in inventory?
**Answer:** Host variables can be defined in several ways:

**In inventory file:**
```ini
[webservers]
web1.example.com http_port=80 server_role=primary
web2.example.com http_port=8080 server_role=secondary
```

**In separate variable files:**
```
inventory/
├── hosts
├── host_vars/
│   ├── web1.example.com.yml
│   └── web2.example.com.yml
└── group_vars/
    └── webservers.yml
```

---

## Modules & Plugins

### Q12: What are Ansible Modules?
**Answer:** Ansible Modules are:
- Reusable units of code that perform specific tasks
- Execute on target hosts and return JSON
- Can be written in any language (Python preferred)
- Idempotent by design
- Categories include: System, Commands, Files, Database, Cloud, etc.

**Common modules:**
- `yum/apt`: Package management
- `service`: Service management
- `copy`: File copying
- `template`: Jinja2 template processing
- `command/shell`: Execute commands

### Q13: What is the difference between command and shell modules?
**Answer:**
- **command module**: 
  - Executes commands without shell processing
  - More secure, no shell injection risks
  - Cannot use shell features (pipes, redirects, variables)
  - Default module for command execution

- **shell module**:
  - Executes commands through shell (/bin/sh)
  - Can use shell features and operators
  - Less secure due to shell processing
  - Use when shell features are needed

**Examples:**
```yaml
# Command module
- name: List files
  command: ls -la /home

# Shell module
- name: Count files
  shell: ls /home | wc -l
```

### Q14: How do you create a custom Ansible module?
**Answer:** Custom modules can be created by:

1. **Creating a Python script:**
```python
#!/usr/bin/python
from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            state=dict(type='str', default='present', choices=['present', 'absent'])
        )
    )
    
    name = module.params['name']
    state = module.params['state']
    
    # Module logic here
    
    module.exit_json(changed=True, msg=f"Module executed for {name}")

if __name__ == '__main__':
    main()
```

2. **Placing it in the library directory or specifying the path**
3. **Using it in playbooks like built-in modules**

---

## Variables & Facts

### Q15: How do you define and use variables in Ansible?
**Answer:** Variables can be defined at multiple levels:

**Priority order (highest to lowest):**
1. Extra vars (`-e` in command line)
2. Task vars
3. Block vars
4. Role and include vars
5. Set_facts / registered vars
6. Host facts
7. Play vars
8. Host vars
9. Group vars
10. Role defaults

**Example usage:**
```yaml
---
- hosts: webservers
  vars:
    http_port: 80
    server_name: "{{ ansible_hostname }}"
  tasks:
    - name: Configure Apache
      template:
        src: httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
      vars:
        ssl_enabled: true
```

### Q16: What are Ansible Facts?
**Answer:** Ansible Facts are:
- System information automatically collected from managed hosts
- Available as variables in playbooks
- Include OS, hardware, network information
- Gathered by the `setup` module at play start
- Can be disabled with `gather_facts: no`

**Example facts:**
```yaml
- debug:
    msg: "OS is {{ ansible_os_family }} {{ ansible_distribution_version }}"
    
- debug:
    msg: "IP address is {{ ansible_default_ipv4.address }}"
```

**Custom facts:**
```bash
# /etc/ansible/facts.d/custom.fact
[database]
version=5.7
port=3306
```

### Q17: How do you register task output as a variable?
**Answer:** Use the `register` keyword:

```yaml
- name: Check disk space
  command: df -h
  register: disk_usage

- name: Display disk usage
  debug:
    var: disk_usage.stdout

- name: Conditional task based on registered variable
  debug:
    msg: "Disk is full"
  when: "'100%' in disk_usage.stdout"
```

---

## Roles & Collections

### Q18: What are Ansible Roles?
**Answer:** Ansible Roles are:
- Reusable automation content with predefined structure
- Organize playbooks, variables, files, templates, and handlers
- Enable content sharing and modularity
- Can be distributed via Ansible Galaxy

**Role structure:**
```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    ├── files/
    ├── vars/
    │   └── main.yml
    ├── defaults/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    └── README.md
```

**Using roles:**
```yaml
- hosts: webservers
  roles:
    - webserver
    - { role: database, db_port: 3306 }
```

### Q19: What are Ansible Collections?
**Answer:** Ansible Collections are:
- Distribution format for Ansible content
- Bundle modules, plugins, roles, and playbooks
- Versioned and distributed via Galaxy or private repositories
- Namespace format: `namespace.collection`

**Installing collections:**
```bash
# Install from Galaxy
ansible-galaxy collection install community.general

# Install from requirements file
ansible-galaxy collection install -r requirements.yml
```

**Using collection content:**
```yaml
- name: Use collection module
  community.general.discord:
    webhook_id: "{{ webhook_id }}"
    webhook_token: "{{ webhook_token }}"
    content: "Deployment completed"
```

### Q20: How do you create and share an Ansible Role?
**Answer:** Creating and sharing roles:

1. **Create role structure:**
```bash
ansible-galaxy init my_role
```

2. **Develop role content in appropriate directories**

3. **Test the role:**
```yaml
- hosts: localhost
  roles:
    - my_role
```

4. **Share via Galaxy:**
```bash
# Login to Galaxy
ansible-galaxy login

# Import from GitHub
ansible-galaxy import github_user repo_name
```

---

## Error Handling & Debugging

### Q21: How do you handle errors in Ansible?
**Answer:** Error handling techniques:

**ignore_errors:**
```yaml
- name: This might fail
  command: /bin/some_command
  ignore_errors: yes
```

**failed_when:**
```yaml
- name: Custom failure condition
  command: echo "Hello"
  failed_when: result.rc != 0
```

**rescue and always blocks:**
```yaml
- block:
    - name: Risky task
      command: /bin/false
  rescue:
    - name: Handle failure
      debug:
        msg: "Task failed, handling it"
  always:
    - name: Cleanup
      debug:
        msg: "This always runs"
```

### Q22: How do you debug Ansible playbooks?
**Answer:** Debugging techniques:

1. **Verbose output:**
```bash
ansible-playbook playbook.yml -v    # basic
ansible-playbook playbook.yml -vvv  # very verbose
```

2. **Debug module:**
```yaml
- debug:
    var: ansible_facts
    
- debug:
    msg: "Variable value is {{ my_var }}"
```

3. **Check mode (dry run):**
```bash
ansible-playbook playbook.yml --check
```

4. **Step mode:**
```bash
ansible-playbook playbook.yml --step
```

5. **Start at specific task:**
```bash
ansible-playbook playbook.yml --start-at-task="task name"
```

### Q23: What is the difference between failed_when and ignore_errors?
**Answer:**
- **failed_when**: Defines custom conditions for task failure
- **ignore_errors**: Continues execution even if task fails

**Examples:**
```yaml
# Custom failure condition
- command: echo "error"
  failed_when: "'error' in result.stdout"

# Ignore all errors
- command: /bin/might_fail
  ignore_errors: yes
```

---

## Security & Best Practices

### Q24: What are Ansible security best practices?
**Answer:** Security best practices include:

**Credential Management:**
- Use Ansible Vault for sensitive data
- Avoid hardcoding passwords in playbooks
- Use SSH keys instead of passwords
- Implement proper user privilege escalation

**Network Security:**
- Use encrypted connections (SSH/WinRM over HTTPS)
- Implement firewall rules for Ansible traffic
- Use jump hosts for isolated environments

**Access Control:**
- Implement role-based access control
- Use separate service accounts for Ansible
- Regular audit of access permissions

**Code Security:**
- Store playbooks in version control
- Code review process for changes
- Use signed commits where possible

### Q25: What is Ansible Vault?
**Answer:** Ansible Vault is:
- Built-in encryption feature for sensitive data
- Encrypts variables, files, or entire playbooks
- Uses AES256 encryption
- Password or key file protected

**Common operations:**
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt vars.yml

# Decrypt file
ansible-vault decrypt vars.yml

# View encrypted file
ansible-vault view secrets.yml

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass
ansible-playbook playbook.yml --vault-password-file vault_pass.txt
```

**Using encrypted variables:**
```yaml
# In encrypted file
database_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653...
```

### Q26: How do you implement privilege escalation in Ansible?
**Answer:** Privilege escalation options:

**Global level (ansible.cfg):**
```ini
[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

**Playbook level:**
```yaml
- hosts: servers
  become: yes
  become_method: sudo
  become_user: root
```

**Task level:**
```yaml
- name: Install package
  yum:
    name: httpd
    state: present
  become: yes
```

**Methods available:**
- `sudo` (default)
- `su`
- `pbrun`
- `pfexec`
- `doas`
- `dzdo`
- `ksu`

---

## Advanced Topics

### Q27: What are Ansible Handlers?
**Answer:** Handlers are:
- Special tasks that run only when notified
- Execute at the end of the play
- Run only once even if notified multiple times
- Useful for service restarts, cleanup tasks

**Example:**
```yaml
tasks:
  - name: Update configuration
    template:
      src: config.j2
      dest: /etc/myapp/config.conf
    notify: restart myapp

handlers:
  - name: restart myapp
    service:
      name: myapp
      state: restarted
```

**Handler features:**
```yaml
# Listen to multiple notifications
handlers:
  - name: restart services
    service:
      name: "{{ item }}"
      state: restarted
    loop:
      - apache
      - mysql
    listen: "restart web stack"

# Force handler execution
- meta: flush_handlers
```

### Q28: What are Ansible Tags?
**Answer:** Tags are:
- Labels applied to tasks, plays, or roles
- Allow selective execution of playbook parts
- Help in organizing and filtering tasks

**Defining tags:**
```yaml
- name: Install packages
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - httpd
    - mysql
  tags:
    - packages
    - webserver

- name: Configure firewall
  firewalld:
    service: http
    state: enabled
  tags:
    - security
    - firewall
```

**Using tags:**
```bash
# Run only tagged tasks
ansible-playbook playbook.yml --tags "packages,security"

# Skip tagged tasks
ansible-playbook playbook.yml --skip-tags "firewall"

# List available tags
ansible-playbook playbook.yml --list-tags
```

### Q29: What are Ansible Loops?
**Answer:** Loops allow iteration over lists, dictionaries, or other data structures:

**Basic loop:**
```yaml
- name: Install packages
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - httpd
    - mysql
    - php
```

**Loop with dictionaries:**
```yaml
- name: Create users
  user:
    name: "{{ item.name }}"
    group: "{{ item.group }}"
    state: present
  loop:
    - { name: alice, group: admin }
    - { name: bob, group: users }
```

**Loop with registered variables:**
```yaml
- name: Check services
  service_facts:
  register: services

- name: Start services
  service:
    name: "{{ item }}"
    state: started
  loop: "{{ services.ansible_facts.services.keys() | list }}"
  when: item.endswith('.service')
```

### Q30: How do you use conditionals in Ansible?
**Answer:** Conditionals control task execution:

**Basic when condition:**
```yaml
- name: Install Apache on RedHat
  yum:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"
```

**Multiple conditions:**
```yaml
- name: Complex condition
  debug:
    msg: "Conditions met"
  when: 
    - ansible_distribution == "Ubuntu"
    - ansible_distribution_version >= "18.04"
    - inventory_hostname in groups['webservers']
```

**Conditional with loops:**
```yaml
- name: Install packages conditionally
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - httpd
    - mysql
    - php
  when: item != "mysql" or install_database
```

---

## Practical Scenarios

### Q31: How would you deploy a web application using Ansible?
**Answer:** Web application deployment playbook:

```yaml
---
- name: Deploy Web Application
  hosts: webservers
  become: yes
  vars:
    app_name: mywebapp
    app_version: "{{ version | default('latest') }}"
    
  tasks:
    - name: Install dependencies
      yum:
        name:
          - httpd
          - python3
          - git
        state: present

    - name: Clone application code
      git:
        repo: https://github.com/user/mywebapp.git
        dest: /var/www/{{ app_name }}
        version: "{{ app_version }}"
      notify: restart apache

    - name: Install Python requirements
      pip:
        requirements: /var/www/{{ app_name }}/requirements.txt

    - name: Configure Apache
      template:
        src: apache.conf.j2
        dest: /etc/httpd/conf.d/{{ app_name }}.conf
      notify: restart apache

    - name: Start and enable Apache
      service:
        name: httpd
        state: started
        enabled: yes

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
```

### Q32: How do you implement rolling updates with Ansible?
**Answer:** Rolling updates using serial execution:

```yaml
---
- name: Rolling Update
  hosts: webservers
  serial: 1  # Update one server at a time
  max_fail_percentage: 0
  
  pre_tasks:
    - name: Remove from load balancer
      uri:
        url: "http://lb.example.com/remove/{{ inventory_hostname }}"
        method: POST

  tasks:
    - name: Stop application
      service:
        name: myapp
        state: stopped

    - name: Update application
      unarchive:
        src: "app-{{ app_version }}.tar.gz"
        dest: /opt/myapp
        remote_src: yes

    - name: Start application
      service:
        name: myapp
        state: started

    - name: Health check
      uri:
        url: "http://{{ inventory_hostname }}:8080/health"
        status_code: 200
      retries: 5
      delay: 10

  post_tasks:
    - name: Add back to load balancer
      uri:
        url: "http://lb.example.com/add/{{ inventory_hostname }}"
        method: POST
```

### Q33: How do you handle different environments (dev, staging, prod)?
**Answer:** Environment management strategies:

**1. Separate inventory files:**
```
inventories/
├── dev/
│   ├── hosts.yml
│   └── group_vars/
├── staging/
│   ├── hosts.yml
│   └── group_vars/
└── prod/
    ├── hosts.yml
    └── group_vars/
```

**2. Environment-specific variables:**
```yaml
# group_vars/all/common.yml
app_name: myapp

# inventories/dev/group_vars/all.yml
environment: development
database_host: dev-db.internal

# inventories/prod/group_vars/all.yml
environment: production
database_host: prod-db.internal
```

**3. Conditional tasks:**
```yaml
- name: Install debug tools
  yum:
    name: strace
    state: present
  when: environment == "development"

- name: Configure production monitoring
  template:
    src: monitoring.conf.j2
    dest: /etc/monitoring.conf
  when: environment == "production"
```

### Q34: How do you test Ansible playbooks?
**Answer:** Testing strategies:

**1. Syntax checking:**
```bash
ansible-playbook --syntax-check playbook.yml
```

**2. Dry run:**
```bash
ansible-playbook --check playbook.yml
```

**3. Molecule testing:**
```bash
# Install molecule
pip install molecule[docker]

# Initialize molecule scenario
molecule init scenario

# Run tests
molecule test
```

**4. Test playbook structure:**
```yaml
# molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: centos:8
provisioner:
  name: ansible
verifier:
  name: ansible
```

**5. Integration testing:**
```yaml
- name: Test web server response
  uri:
    url: http://localhost:80
    return_content: yes
  register: webpage
  
- name: Verify content
  assert:
    that:
      - webpage.status == 200
      - "'Welcome' in webpage.content"
```

### Q35: How do you optimize Ansible performance?
**Answer:** Performance optimization techniques:

**1. Connection optimization:**
```ini
# ansible.cfg
[defaults]
host_key_checking = False
pipelining = True

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
control_path_dir = /tmp/.ansible-cp
```

**2. Parallelism:**
```yaml
# Increase parallel execution
- hosts: all
  strategy: free  # Don't wait for all hosts to complete each task
  forks: 20      # Increase parallel processes
```

**3. Fact caching:**
```ini
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/facts_cache
fact_caching_timeout = 86400
```

**4. Selective fact gathering:**
```yaml
- hosts: all
  gather_facts: no
  tasks:
    - setup:
        filter: ansible_distribution*
```

**5. Task optimization:**
```yaml
# Use package module instead of specific ones
- package:
    name: "{{ packages }}"
    state: present
  vars:
    packages:
      - httpd
      - mysql
      - php

# Combine operations
- lineinfile:
    path: /etc/hosts
    line: "{{ item }}"
  loop:
    - "192.168.1.1 server1"
    - "192.168.1.2 server2"
```

---

## Interview Tips

### Technical Preparation
1. **Hands-on Practice**: Set up lab environment and practice common scenarios
2. **Version Awareness**: Stay updated with latest Ansible features and changes
3. **Integration Knowledge**: Understand how Ansible integrates with CI/CD, cloud platforms
4. **Troubleshooting**: Practice debugging failed playbooks and connection issues

### Common Interview Formats
1. **Theoretical Questions**: Concepts, best practices, architecture
2. **Practical Tasks**: Write playbooks, debug issues, optimize performance
3. **Scenario-based**: Real-world deployment and management situations
4. **Code Review**: Analyze and improve existing playbooks

### Best Practices to Highlight
- Always use version control for playbooks
- Implement proper testing strategies
- Follow security best practices
- Use roles and collections for reusability
- Document your automation code
- Monitor and maintain automation infrastructure

### Red Flags to Avoid
- Hardcoding sensitive information
- Not using idempotent operations
- Ignoring error handling
- Poor organization of playbooks and roles
- Not testing automation code
- Overly complex playbooks

---

## Additional Resources

- [Official Ansible Documentation](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Ansible GitHub Repository](https://github.com/ansible/ansible)
- [Red Hat Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

Remember: The key to succeeding in an Ansible interview is demonstrating both theoretical knowledge and practical experience. Be prepared to explain concepts clearly and provide real-world examples of how you've used Ansible to solve automation challenges.
