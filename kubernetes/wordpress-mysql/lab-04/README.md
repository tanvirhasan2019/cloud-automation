# Kubernetes Enterprise WordPress Deployment - Lab 04

## 1. Overview

Lab 04 completes our Kubernetes learning progression with an enterprise-grade WordPress deployment. This lab demonstrates advanced deployment patterns, integrates service mesh, implements GitOps workflows, and incorporates production-level monitoring and security. Using Helm charts and environment-specific configurations, you'll build a scalable, resilient, and secure WordPress platform ready for enterprise use.

## 2. Prerequisites

- A Kubernetes cluster (EKS, GKE, AKS, or local minikube/kind/k3s)
- `kubectl` configured to communicate with your cluster
- Helm 3.x installed (`curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`)
- `istioctl` installed for service mesh capabilities
- Domain name for Ingress configurations (or use a local hosts file entry)
- Basic understanding of Kubernetes and previous labs (1-3)

## 3. Objectives

- Deploy WordPress and MySQL using Helm charts with enterprise configurations
- Implement multi-environment deployment strategies (dev/staging/production)
- Configure service mesh for advanced traffic management
- Set up comprehensive monitoring with Prometheus and Grafana
- Establish GitOps workflow for continuous deployment
- Implement production-grade security practices
- Configure backup and recovery mechanisms

## 4. Directory Structure

```
lab-04/
├── charts/
│   ├── wordpress/           # WordPress Helm chart
│   └── mysql/               # MySQL Helm chart with replication
├── infrastructure/
│   ├── istio/               # Service mesh configuration
│   ├── monitoring/          # Prometheus and Grafana setup
│   ├── security/            # Network policies and security controls
│   └── cert-manager/        # TLS certificate automation
├── gitops/
│   ├── flux/                # Flux configuration
│   └── argocd/              # ArgoCD configuration
├── environments/
│   ├── dev/                 # Development environment configs
│   ├── staging/             # Staging environment configs
│   └── production/          # Production environment configs
└── README.md
```

## 5. Step-by-Step Guide

### a. Install Infrastructure Components

First, install required infrastructure components:

```bash
# Install Istio service mesh
istioctl install --set profile=demo

# Install cert-manager for TLS certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

# Install Prometheus operator for monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Add namespace labels for Istio injection
kubectl label namespace default istio-injection=enabled
```

### b. Deploy MySQL Database

```bash
# Create required secrets
kubectl create secret generic mysql-credentials \
  --from-literal=mysql-root-password=rootpassword \
  --from-literal=mysql-password=wppassword \
  --from-literal=mysql-replication-password=replpassword

# Deploy MySQL with Helm
helm install mysql ./charts/mysql -f ./environments/production/values-override.yaml
```

### c. Deploy WordPress Application

```bash
# Create WordPress secrets
kubectl create secret generic wordpress-credentials \
  --from-literal=wp-password=wppassword

# Deploy WordPress with Helm
helm install wordpress ./charts/wordpress -f ./environments/production/values-override.yaml
```

### d. Configure Ingress and TLS

```bash
# Apply ClusterIssuer for certificates
kubectl apply -f ./infrastructure/cert-manager/cluster-issuer.yaml

# Apply Istio Gateway and Virtual Service
kubectl apply -f ./infrastructure/istio/gateway.yaml
kubectl apply -f ./infrastructure/istio/virtual-service.yaml
```

### e. Set Up GitOps (Choose one)

For Flux:
```bash
# Install Flux components
kubectl apply -f ./gitops/flux/gotk-components.yaml

# Configure GitOps workflow
kubectl apply -f ./gitops/flux/gotk-sync.yaml
```

For ArgoCD:
```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply WordPress application
kubectl apply -f ./gitops/argocd/application.yaml
```

### f. Apply Security Policies

```bash
# Apply network policies
kubectl apply -f ./infrastructure/security/network-policies.yaml

# Apply pod security standards
kubectl apply -f ./infrastructure/security/pod-security-standards.yaml
```

## 6. Validation and Testing

Verify your deployment with these commands:

```bash
# Check WordPress deployment
kubectl get deployments,pods,svc -l app.kubernetes.io/name=wordpress

# Verify MySQL StatefulSet and replication
kubectl get statefulsets,pods,svc -l app.kubernetes.io/name=mysql

# Test connectivity to the WordPress application
curl -I https://wordpress.example.com

# Check HPA configuration
kubectl get hpa

# Verify GitOps setup
kubectl get gitrepositories,kustomizations -n flux-system
# or
kubectl get applications -n argocd
```

## 7. Access Grafana Dashboards

Access the pre-configured monitoring dashboards:

```bash
# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward Grafana service
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open your browser at http://localhost:3000 and navigate to the WordPress and MySQL dashboards.

## 8. Advanced Exercises

- Implement a canary deployment for WordPress using Istio
- Set up a scheduled backup for both WordPress and MySQL
- Configure alerts in Prometheus for critical conditions
- Test scaling with artificial load using a tool like Apache JMeter
- Implement a blue/green deployment pattern

## 9. Learning Outcomes

After completing this lab, you should understand:

- Enterprise-grade Kubernetes deployment patterns
- How to structure multi-environment configurations
- Service mesh capabilities for traffic management and security
- GitOps-based deployment strategies
- Comprehensive monitoring and observability in Kubernetes
- Production security best practices
- High availability and disaster recovery approaches

## 10. Cleanup

To remove all resources created in this lab:

```bash
# Remove applications
helm uninstall wordpress mysql

# Remove infrastructure components
kubectl delete -f ./infrastructure/istio/
kubectl delete -f ./infrastructure/cert-manager/
helm uninstall prometheus -n monitoring

# Remove GitOps components
kubectl delete -f ./gitops/flux/
# or
kubectl delete -f ./gitops/argocd/

# Remove namespaces (optional)
kubectl delete namespace monitoring argocd flux-system
```