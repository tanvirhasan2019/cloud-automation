# Lab 04: Enterprise-Grade Kubernetes Architecture

## Overview

This final lab transforms our WordPress and MySQL deployment into an enterprise-ready application platform using advanced Kubernetes patterns and tools. We'll implement:

1. **Helm Charts** for package management
2. **Service Mesh** (Istio) for advanced networking
3. **Monitoring Stack** with Prometheus and Grafana
4. **GitOps** with Flux CD
5. **Multi-cluster** configuration for high availability

## Prerequisites

- Kubernetes cluster (v1.24+)
- Helm 3.x
- kubectl configured
- Basic understanding of previous labs
- Recommended: 4+ CPU cores, 8GB+ RAM

## Lab Objectives

- Implement WordPress and MySQL as Helm charts
- Install and configure Istio service mesh
- Set up monitoring with Prometheus and Grafana
- Configure GitOps with Flux CD
- Create multi-cluster configuration for disaster recovery

## Directory Structure

```
lab-04/
├── README.md                                # Lab instructions
├── helm-charts/                             # Helm charts for our applications
│   ├── wordpress/                           # WordPress Helm chart
│   │   ├── Chart.yaml                       # Chart metadata
│   │   ├── values.yaml                      # Default configuration values
│   │   ├── templates/                       # Kubernetes resource templates
│   │   │   ├── _helpers.tpl                 # Template helpers
│   │   │   ├── deployment.yaml              # WordPress deployment
│   │   │   ├── hpa.yaml                     # Horizontal Pod Autoscaler
│   │   │   ├── ingress.yaml                 # Ingress resource
│   │   │   ├── pvc.yaml                     # Persistent Volume Claim
│   │   │   ├── secrets.yaml                 # WordPress secrets
│   │   │   ├── service.yaml                 # WordPress service
│   │   │   ├── serviceaccount.yaml          # Service account
│   │   │   └── configmap.yaml               # WordPress configuration
│   │   └── values-production.yaml           # Production-specific values
│   └── mysql/                               # MySQL Helm chart
│       ├── Chart.yaml                       # Chart metadata
│       ├── values.yaml                      # Default configuration values
│       ├── templates/                       # Kubernetes resource templates
│       │   ├── _helpers.tpl                 # Template helpers
│       │   ├── configmap.yaml               # MySQL configuration
│       │   ├── headless-service.yaml        # Headless service for StatefulSet
│       │   ├── pvc.yaml                     # Persistent Volume Claim template
│       │   ├── secrets.yaml                 # MySQL secrets
│       │   ├── serviceaccount.yaml          # Service account
│       │   └── statefulset.yaml             # MySQL StatefulSet
│       └── values-production.yaml           # Production-specific values
├── monitoring/                              # Monitoring configuration
│   ├── grafana/
│   │   ├── dashboard-configmap.yaml         # Pre-configured dashboards
│   │   └── grafana-values.yaml              # Grafana Helm values
│   ├── prometheus/
│   │   ├── prometheus-values.yaml           # Prometheus Helm values
│   │   └── service-monitors/                # ServiceMonitor CRDs
│   │       ├── mysql-servicemonitor.yaml    # MySQL monitoring config
│   │       └── wordpress-servicemonitor.yaml # WordPress monitoring config
│   └── kube-prometheus-stack.yaml           # Helm release for Prometheus stack
├── service-mesh/                            # Istio service mesh config
│   ├── istio-installation.yaml              # IstioOperator resource
│   ├── wordpress-gateway.yaml               # Istio Gateway for WordPress
│   ├── wordpress-virtualservice.yaml        # VirtualService for traffic routing
│   └── mysql-destinationrule.yaml           # DestinationRule for MySQL connections
├── gitops/                                  # GitOps with Flux configuration
│   ├── flux-installation.yaml               # Flux bootstrap configuration
│   ├── wordpress-helmrelease.yaml           # HelmRelease for WordPress
│   ├── mysql-helmrelease.yaml               # HelmRelease for MySQL
│   └── kustomization.yaml                   # Kustomization resource
└── multi-cluster/                           # Multi-cluster configuration
    ├── cluster-config/                      # Configuration for clusters
    │   ├── primary/                         # Primary cluster config
    │   │   └── values-override.yaml         # Value overrides for primary
    │   └── dr-cluster/                      # Disaster recovery cluster
    │       └── values-override.yaml         # Value overrides for DR
    └── global-load-balancing/               # Cross-cluster service discovery
        └── wordpress-gslb.yaml              # Global load balancing config
```

## Step-by-Step Guide

### 1. Install Helm Charts

First, deploy MySQL and WordPress using the Helm charts:

```bash
# Create namespace
kubectl create namespace wordpress

# Deploy MySQL
helm upgrade --install mysql ./helm-charts/mysql \
  --namespace wordpress \
  --values ./helm-charts/mysql/values.yaml

# Deploy WordPress
helm upgrade --install wordpress ./helm-charts/wordpress \
  --namespace wordpress \
  --values ./helm-charts/wordpress/values.yaml \
  --set mysql.host=mysql-primary
```

### 2. Set Up Istio Service Mesh

```bash
# Create istio-system namespace
kubectl create namespace istio-system

# Install Istio with IstioOperator
kubectl apply -f service-mesh/istio-installation.yaml

# Enable sidecar injection for wordpress namespace
kubectl label namespace wordpress istio-injection=enabled

# Apply Gateway and VirtualService
kubectl apply -f service-mesh/wordpress-gateway.yaml
kubectl apply -f service-mesh/wordpress-virtualservice.yaml
kubectl apply -f service-mesh/mysql-destinationrule.yaml
```

### 3. Install Monitoring Stack

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus and Grafana
kubectl apply -f monitoring/kube-prometheus-stack.yaml

# Apply ServiceMonitors
kubectl apply -f monitoring/prometheus/service-monitors/
```

### 4. Set Up GitOps with Flux CD

```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux (adjust GitHub parameters accordingly)
flux bootstrap github \
  --owner=YOUR_GITHUB_USER \
  --repository=k8s-wordpress-gitops \
  --branch=main \
  --path=./clusters/my-cluster \
  --personal

# Apply Flux resources
kubectl apply -f gitops/wordpress-helmrelease.yaml
kubectl apply -f gitops/mysql-helmrelease.yaml
kubectl apply -f gitops/kustomization.yaml
```

### 5. Configure Multi-Cluster Deployment

For this step, you'll need a second Kubernetes cluster:

```bash
# In your primary cluster
kubectl apply -f multi-cluster/cluster-config/primary/values-override.yaml

# In your DR cluster
kubectl apply -f multi-cluster/cluster-config/dr-cluster/values-override.yaml

# Set up global load balancing (if using a supported platform)
kubectl apply -f multi-cluster/global-load-balancing/wordpress-gslb.yaml
```

## Validation and Testing

### Test WordPress Deployment

```bash
# Get Istio ingress gateway IP
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Access WordPress
echo "Access WordPress at: http://$INGRESS_HOST"
```

### Access Grafana Dashboards

```bash
# Port-forward Grafana service
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Access Grafana at http://localhost:3000
# Default credentials: admin/prom-operator
```

## Advanced Exercises

1. Implement canary deployments using Istio traffic splitting
2. Set up disaster recovery testing between clusters
3. Create custom Prometheus alerting rules
4. Implement horizontal pod autoscaling based on custom metrics
5. Set up automated backup and restore across clusters

## Cleanup

```bash
# Remove all resources
helm uninstall wordpress mysql -n wordpress
kubectl delete namespace wordpress
kubectl delete -f service-mesh/
kubectl delete -f monitoring/
flux uninstall --namespace=flux-system
kubectl delete namespace istio-system monitoring flux-system
```

## Next Steps

- Explore Kubernetes Operators for automated management
- Implement policy enforcement with OPA/Gatekeeper
- Deploy serverless workloads with Knative
- Set up CI/CD pipelines with Tekton or ArgoCD
