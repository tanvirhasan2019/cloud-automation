# Kubernetes Lab 2: Advanced WordPress & MySQL Setup

A more advanced Kubernetes lab demonstrating deployments, configs, secrets, persistent storage, and auto-scaling.

## Prerequisites

- Kubernetes cluster (Minikube, kind, or k3s)
- kubectl configured
- metrics-server installed (for HPA)

## Lab Setup

### 1. Create Namespace

```bash
kubectl create namespace lab2
```

### 2. Deploy All Components

```bash
# Apply all configuration files
kubectl apply -f mysql-secret.yaml
kubectl apply -f wordpress-configmap.yaml
kubectl apply -f mysql-pvc.yaml
kubectl apply -f wordpress-pvc.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml
kubectl apply -f wordpress-deployment.yaml
kubectl apply -f wordpress-service.yaml
kubectl apply -f wordpress-hpa.yaml
```

### 3. Verify Deployment

```bash
# Check all resources
kubectl get all -n lab2
```

### 4. Access WordPress

```bash
# If using Minikube
minikube service wordpress-service -n lab2 --url

# Otherwise, access via NodePort
http://<your-ubuntu-machine-ip>:30002
```

### 5. Cleanup

When you're done with the lab:

```bash
kubectl delete namespace lab2
```

## Component Overview

- **ConfigMap & Secret** - Configuration and sensitive data management
- **PVCs** - Persistent storage for both MySQL and WordPress
- **Deployments** - Multi-replica setup with health checks
- **Services** - Network exposure for applications
- **HPA** - Automatic scaling based on CPU usage

## Key Learning Points

- Rolling update strategies
- Resource management with limits and requests
- Health monitoring with probes
- Horizontal scaling
