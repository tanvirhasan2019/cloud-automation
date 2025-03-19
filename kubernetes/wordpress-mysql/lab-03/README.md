# Kubernetes Lab 3: Production-Ready WordPress & MySQL

A production-grade WordPress and MySQL deployment with security, scalability, and automation features.

## Setup Instructions

### 1. Create Namespace
```bash
kubectl create namespace lab3
```

### 2. Deploy Components
```bash
# Security
kubectl apply -f security/rbac.yaml
kubectl apply -f security/mysql-service-account.yaml
kubectl apply -f security/pod-security-standards.yaml

# TLS (for local testing)
kubectl apply -f tls-local/local-tls-cert.yaml
# Or for production with cert-manager:
# kubectl apply -f tls/cluster-issuer-staging.yaml

# MySQL
kubectl apply -f mysql/mysql-config.yaml
kubectl apply -f mysql/mysql-secret.yaml
kubectl apply -f mysql/mysql-pvc.yaml
kubectl apply -f mysql/backup-pvc.yaml
kubectl apply -f mysql/mysql-headless-service.yaml
kubectl apply -f mysql/mysql-deployment.yaml
kubectl apply -f mysql/mysql-backup-cronjob.yaml

# WordPress
kubectl apply -f wordpress/wordpress-configmap.yaml
kubectl apply -f wordpress/wordpress-pvc.yaml
kubectl apply -f wordpress/wordpress-ingress-local.yaml
kubectl apply -f wordpress/wordpress-deployment.yaml
kubectl apply -f wordpress/wordpress-service.yaml
kubectl apply -f wordpress/wordpress-nodeport-service.yaml
kubectl apply -f wordpress/wordpress-hpa.yaml
```

### 3. Access WordPress
```bash
# Via NodePort
http://<node-ip>:30003

# Via Ingress (add to /etc/hosts first: 127.0.0.1 wordpress.local)
kubectl apply -f wordpress/wordpress-ingress-local.yaml
http://wordpress.local
```

### 4. Verify Deployment
```bash
kubectl get all -n lab3
```

### 5. Clean Up
```bash
kubectl delete namespace lab3
```

## Key Features

- MySQL with configurable settings and backups
- WordPress with multiple replicas and autoscaling
- RBAC security controls
- TLS encryption for secure access
- Health checks and resource limits
- Persistent storage for data durability
