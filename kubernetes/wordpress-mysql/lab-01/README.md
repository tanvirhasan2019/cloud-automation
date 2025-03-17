# Kubernetes Lab 1: WordPress & MySQL Setup

A basic Kubernetes lab demonstrating how to run WordPress with MySQL on a local Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (Minikube, kind, or k3s)
- kubectl configured
- Basic knowledge of Kubernetes

## Lab Setup

### 1. Create Namespace

```bash
kubectl create namespace lab1
```

### 2. Deploy MySQL and WordPress

```bash
# Apply all configuration files
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml
kubectl apply -f wordpress-deployment.yaml
kubectl apply -f wordpress-service.yaml
```

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -n lab1

# Check services
kubectl get services -n lab1
```

### 4. Access WordPress

```bash
# If using Minikube
minikube service wordpress-service -n lab1 --url

# Otherwise, access via NodePort
http://<your-ubuntu-machine-ip>:30001
```

### 5. Cleanup

When you're done with the lab:

```bash
kubectl delete namespace lab1
```

## Component Overview

- **PVC** - Persistent storage for MySQL data
- **Pods** - MySQL and WordPress containers
- **Services** - Network exposure for MySQL (internal) and WordPress (external)

## Next Steps

After completing this lab, continue to Lab 2 to learn about Deployments, ConfigMaps, and more advanced Kubernetes concepts.
