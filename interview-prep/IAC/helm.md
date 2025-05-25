# Helm Chart for Microservices - Interview Preparation Guide

## Overview
This guide covers essential concepts, common interview questions, and practical examples for designing Helm charts for microservices applications.

## Table of Contents
1. [Core Concepts](#core-concepts)
2. [Common Interview Questions](#common-interview-questions)
3. [Practical Examples](#practical-examples)
4. [Best Practices](#best-practices)
5. [Advanced Topics](#advanced-topics)

## Core Concepts

### What is Helm?
Helm is a package manager for Kubernetes that helps you manage Kubernetes applications through charts. A Helm chart is a collection of files that describe a related set of Kubernetes resources.

### Key Components of a Helm Chart
- **Chart.yaml**: Metadata about the chart
- **values.yaml**: Default configuration values
- **templates/**: Directory containing Kubernetes manifest templates
- **charts/**: Directory for chart dependencies
- **templates/NOTES.txt**: Usage notes displayed after installation

## Common Interview Questions

### Q1: How would you design a Helm chart structure for a microservices application?

**Answer:**
```
microservices-app/
├── Chart.yaml
├── values.yaml
├── charts/
│   ├── frontend/
│   ├── api-gateway/
│   ├── user-service/
│   ├── order-service/
│   └── payment-service/
├── templates/
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── ingress.yaml
│   └── NOTES.txt
└── requirements.yaml
```

**Key Design Principles:**
- Use subchart pattern for individual microservices
- Shared resources (ingress, secrets) in parent chart
- Each microservice as independent subchart
- Global values for cross-cutting concerns

### Q2: How do you handle configuration management across multiple microservices?

**Answer:**
Use a hierarchical values structure:

```yaml
# values.yaml
global:
  database:
    host: postgres.default.svc.cluster.local
    port: 5432
  redis:
    host: redis.default.svc.cluster.local
  image:
    registry: docker.io
    pullPolicy: IfNotPresent

frontend:
  enabled: true
  replicaCount: 2
  image:
    repository: myapp/frontend
    tag: "1.0.0"

userService:
  enabled: true
  replicaCount: 3
  image:
    repository: myapp/user-service
    tag: "1.0.0"
  database:
    name: users_db
```

### Q3: How do you manage dependencies between microservices in Helm?

**Answer:**
Use Chart dependencies and init containers:

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: 11.6.12
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: 16.4.0
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

```yaml
# Deployment template with init container
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1.28
        command: ['sh', '-c', 'until nc -z {{ .Values.global.database.host }} {{ .Values.global.database.port }}; do sleep 1; done']
      containers:
      - name: {{ .Chart.Name }}
        # main container spec
```

### Q4: How do you implement service discovery in a Helm chart?

**Answer:**
Use Kubernetes DNS and service templates:

```yaml
# templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "microservice.fullname" . }}
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "microservice.selectorLabels" . | nindent 4 }}
```

Services can then discover each other using:
- `user-service.default.svc.cluster.local`
- Environment variables injected by Kubernetes

### Q5: How do you handle secrets and sensitive data?

**Answer:**
Multiple approaches:

1. **Kubernetes Secrets:**
```yaml
# templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "app.fullname" . }}-secrets
type: Opaque
data:
  database-password: {{ .Values.secrets.databasePassword | b64enc }}
  api-key: {{ .Values.secrets.apiKey | b64enc }}
```

2. **External Secret Management:**
```yaml
# Using External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
```

3. **Sealed Secrets:**
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: mysecret
spec:
  encryptedData:
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
```

### Q6: How do you implement rolling updates and zero-downtime deployments?

**Answer:**
```yaml
# Deployment strategy
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 15
```

### Q7: How do you handle environment-specific configurations?

**Answer:**
Use multiple values files:

```bash
# Directory structure
environments/
├── development.yaml
├── staging.yaml
└── production.yaml
```

```yaml
# environments/production.yaml
global:
  environment: production
  
frontend:
  replicaCount: 5
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

userService:
  replicaCount: 10
  autoscaling:
    enabled: true
    minReplicas: 5
    maxReplicas: 20
```

Deploy with:
```bash
helm install myapp ./microservices-app -f environments/production.yaml
```

### Q8: How do you implement monitoring and observability?

**Answer:**
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "app.fullname" . }}
spec:
  selector:
    matchLabels:
      {{- include "app.selectorLabels" . | nindent 6 }}
  endpoints:
  - port: metrics
    path: /metrics
```

```yaml
# Deployment with monitoring
spec:
  template:
    spec:
      containers:
      - name: {{ .Chart.Name }}
        ports:
        - name: metrics
          containerPort: 9090
        env:
        - name: JAEGER_AGENT_HOST
          value: {{ .Values.jaeger.agent.host }}
```

## Practical Examples

### Complete Microservice Chart Template

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "microservice.fullname" . }}
  labels:
    {{- include "microservice.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "microservice.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      labels:
        {{- include "microservice.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "microservice.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: {{ .Values.healthcheck.liveness.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.liveness.periodSeconds }}
          readinessProbe:
            httpGet:
              path: {{ .Values.healthcheck.readiness.path }}
              port: http
            initialDelaySeconds: {{ .Values.healthcheck.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.healthcheck.readiness.periodSeconds }}
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ include "microservice.fullname" . }}-secrets
                  key: database-url
          envFrom:
            - configMapRef:
                name: {{ include "microservice.fullname" . }}-config
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

## Best Practices

### 1. Chart Organization
- Use subcharts for complex applications
- Keep shared resources in parent chart
- Use consistent naming conventions
- Version your charts properly

### 2. Values Management
- Provide sensible defaults
- Use global values for shared configuration
- Document all values in comments
- Validate values with JSON Schema

### 3. Security
- Never hardcode secrets in templates
- Use least privilege principles
- Implement proper RBAC
- Scan images for vulnerabilities

### 4. Testing
```bash
# Lint your charts
helm lint ./microservices-app

# Test rendering
helm template myapp ./microservices-app

# Dry run installation
helm install myapp ./microservices-app --dry-run

# Use helm test for validation
helm test myapp
```

### 5. CI/CD Integration
```yaml
# .github/workflows/helm.yml
name: Helm Chart CI
on:
  push:
    paths:
    - 'charts/**'
jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: azure/setup-helm@v1
    - run: helm lint charts/microservices-app
    - run: helm template test charts/microservices-app
```

## Advanced Topics

### Custom Resource Definitions
```yaml
# templates/crd.yaml
{{- if .Values.customResources.enabled }}
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: microserviceconfigs.example.com
spec:
  group: example.com
  versions:
  - name: v1
    served: true
    storage: true
{{- end }}
```

### Hooks and Jobs
```yaml
# templates/pre-install-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "app.fullname" . }}-migration
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      containers:
      - name: migration
        image: "{{ .Values.migration.image }}"
        command: ["./migrate.sh"]
      restartPolicy: Never
```

### Advanced Templating
```yaml
{{/* Generate database connection string */}}
{{- define "app.databaseUrl" -}}
{{- if .Values.postgresql.enabled -}}
postgresql://{{ .Values.postgresql.auth.username }}:{{ .Values.postgresql.auth.password }}@{{ include "postgresql.primary.fullname" .Subcharts.postgresql }}:5432/{{ .Values.postgresql.auth.database }}
{{- else -}}
{{ .Values.externalDatabase.url }}
{{- end -}}
{{- end -}}
```

## Interview Tips

1. **Understand the Architecture**: Be able to explain microservices patterns and how Helm fits
2. **Know the Ecosystem**: Understand how Helm integrates with CI/CD, monitoring, and security tools
3. **Practical Experience**: Be ready to write chart templates on the spot
4. **Troubleshooting**: Know common issues and how to debug Helm deployments
5. **Best Practices**: Emphasize security, maintainability, and operational concerns

## Common Gotchas to Discuss
- Chart dependency management complexity
- Values precedence and merging behavior
- Upgrade and rollback strategies
- Resource quotas and limits
- Network policies and service mesh integration
- Multi-cluster deployments

## Study Resources
- Official Helm documentation
- Kubernetes networking concepts
- Container orchestration patterns
- Infrastructure as Code principles
- GitOps workflows
