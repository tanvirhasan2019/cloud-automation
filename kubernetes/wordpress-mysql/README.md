# Kubernetes Learning Path: WordPress & MySQL

This repository contains a progressive series of Kubernetes labs that demonstrate how to deploy, scale, and manage WordPress with MySQL. Each lab builds upon the previous one, introducing new concepts and best practices for operating applications in Kubernetes.

## Repository Structure

```
kubernetes-learning-path/
├── lab1/ - Basic Deployment
├── lab2/ - Scalability & Configuration
├── lab3/ - Production Readiness
└── lab4/ - Enterprise Architecture
```

## Lab Overview

| Lab | Level | Focus | Key Concepts |
|-----|-------|-------|-------------|
| Lab 1 | Beginner | Basic Deployment | Pods, Services, PVCs, Namespaces, Environment Variables |
| Lab 2 | Intermediate | Scalability & Reliability | Deployments, Secrets, ConfigMaps, HPA, Resource Limits, Probes |
| Lab 3 | Advanced | Production Readiness | StatefulSets, Ingress, CronJobs (Backup), RBAC, Network Policies |
| Lab 4 | Expert | Enterprise Architecture | Helm Charts, Service Mesh, Prometheus/Grafana, Multi-Cluster, GitOps |

## Learning Progression

| Lab | Goal | What's Missing for Production |
|-----|------|------------------------------|
| Lab 1 | "Making it work" - Basic functionality | Security, scalability, self-healing, configuration management |
| Lab 2 | "Making it reliable" - Operational improvements | Database replication, TLS, backups, RBAC |
| Lab 3 | "Making it secure" - Production hardening | Multi-cluster support, advanced traffic management, GitOps |
| Lab 4 | "Making it enterprise-ready" - Advanced architecture | None! (Fully production-ready) |

## Getting Started

Each lab directory contains:
- YAML manifest files
- A detailed README with step-by-step instructions
- Documentation on the concepts introduced

### Prerequisites

- Kubernetes cluster (Minikube, kind, or k3s for local development)
- kubectl command-line tool
- Basic understanding of Kubernetes concepts
- For advanced labs: Helm, metrics-server, and other tools as specified

Begin with Lab 1 and progress through each lab to build a comprehensive understanding of Kubernetes deployment patterns and best practices.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
