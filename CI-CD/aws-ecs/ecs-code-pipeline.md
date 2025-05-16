# AWS ECS CI/CD (Cloudformation, Code-Pipeline)

## Table of Contents
- [Introduction](#introduction)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Setup and Configuration](#setup-and-configuration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Best Practices](#security-best-practices)
- [Monitoring and Logging](#monitoring-and-logging)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [References](#references)

## Introduction

This repository contains best practices for implementing a robust CI/CD pipeline for AWS Elastic Container Service (ECS). The goal is to provide a standardized, repeatable, and secure approach to deploying containerized applications to AWS ECS.

### Benefits of Implementing These Best Practices

- **Faster Deployments**: Automated pipelines reduce deployment time from hours to minutes
- **Consistent Environments**: Ensure parity across development, testing, and production
- **Improved Quality**: Automated testing reduces the risk of bugs in production
- **Enhanced Security**: Security checks are integrated throughout the pipeline
- **Cost Efficiency**: Optimal resource allocation and utilization

## Architecture Overview

![AWS ECS CI/CD Architecture](https://via.placeholder.com/800x400)

Our reference architecture uses the following AWS services:

- **AWS CodeCommit/GitHub**: Source code repository
- **AWS CodeBuild**: Build and test Docker images
- **AWS CodePipeline**: Orchestrate the CI/CD workflow
- **Amazon ECR**: Store Docker images
- **AWS ECS**: Run containerized applications
- **AWS CloudFormation/CDK**: Infrastructure as Code (IaC)
- **AWS Secrets Manager**: Securely store and manage secrets
- **AWS CloudWatch**: Monitoring and logging

## Prerequisites

- AWS Account with administrator access
- AWS CLI installed and configured
- Docker installed locally for development and testing
- Basic understanding of containerization concepts
- IAM roles and policies for CI/CD services

## Setup and Configuration

### 1. Infrastructure Setup with CloudFormation/CDK

```yaml
# Example CloudFormation template snippet for ECS Cluster
Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub ${AWS::StackName}-cluster
      ClusterSettings:
        - Name: containerInsights
          Value: enabled
      CapacityProviders:
        - FARGATE
        - FARGATE_SPOT
      DefaultCapacityProviderStrategy:
        - CapacityProvider: FARGATE
          Weight: 1
          Base: 1
        - CapacityProvider: FARGATE_SPOT
          Weight: 4
```

### 2. ECR Repository Creation

```bash
aws ecr create-repository \
    --repository-name my-application \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=KMS
```

### 3. Task Definition Setup

Create a `task-definition.json` file:

```json
{
  "family": "my-application",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/my-application:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-application",
          "awslogs-region": "REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

## CI/CD Pipeline

### 1. CodePipeline Configuration

```yaml
# buildspec.yml for AWS CodeBuild
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/my-application
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
      - echo Running static code analysis...
      - npm run lint
      - echo Running unit tests...
      - npm test
  
  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
      - echo Running security scan on Docker image...
      - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy $REPOSITORY_URI:$IMAGE_TAG
  
  post_build:
    commands:
      - echo Pushing the Docker image...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - aws ecs describe-task-definition --task-definition my-application --query taskDefinition > task-definition.json
      - envsubst < appspec_template.yaml > appspec.yaml
      - envsubst < taskdef_template.json > taskdef.json

artifacts:
  files:
    - appspec.yaml
    - taskdef.json
    - task-definition.json
  discard-paths: yes
```

### 2. Blue/Green Deployment Strategy

```yaml
# appspec.yaml for AWS CodeDeploy
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: "app"
          ContainerPort: 8080
        PlatformVersion: "LATEST"
Hooks:
  - BeforeInstall: "LambdaFunctionToValidateBeforeInstall"
  - AfterInstall: "LambdaFunctionToValidateDeployment"
  - AfterAllowTestTraffic: "LambdaFunctionToValidateTestTraffic"
  - BeforeAllowTraffic: "LambdaFunctionToRunFinalTests"
  - AfterAllowTraffic: "LambdaFunctionToValidateProduction"
```

### 3. Pipeline Workflow

1. **Source Stage**: Detect changes in repository (GitHub or CodeCommit)
2. **Build Stage**: 
   - Build Docker image
   - Run unit tests
   - Perform static code analysis
   - Scan for security vulnerabilities
3. **Deployment Stage**:
   - Update ECS task definition
   - Deploy using blue/green or rolling update strategy
4. **Testing Stage**:
   - Run integration tests against the new deployment
5. **Production Stage**:
   - Shift traffic to new deployment if tests pass

## Security Best Practices

1. **Image Scanning**:
   - Enable automatic scanning in ECR
   - Implement vulnerability scanning with tools like Clair, Trivy, or Snyk
   - Block deployments with critical vulnerabilities

2. **Secrets Management**:
   - Use AWS Secrets Manager or Parameter Store for secrets
   - Never hardcode credentials in Docker images
   - Implement least privilege for task roles

   ```bash
   # Example of retrieving a secret in your application
   aws secretsmanager get-secret-value --secret-id my-app-secrets --query SecretString --output text
   ```

3. **Network Security**:
   - Use private subnets for ECS tasks
   - Implement security groups with least privilege
   - Enable VPC Flow Logs for network monitoring

4. **IAM Roles**:
   - Create specific IAM roles for each service
   - Implement role-based access control
   - Regularly audit and rotate credentials

## Monitoring and Logging

1. **CloudWatch Container Insights**:
   - Enable Container Insights for ECS clusters
   - Set up custom metrics and dashboards
   - Configure appropriate alarms

2. **Centralized Logging**:
   - Configure the awslogs driver for containers
   - Set up log retention policies
   - Consider using CloudWatch Logs Insights for log analysis

3. **Tracing with AWS X-Ray**:
   - Instrument your application with X-Ray SDK
   - Analyze service maps and trace details
   - Identify performance bottlenecks

```yaml
# X-Ray daemon as a sidecar container in task definition
{
  "name": "xray-daemon",
  "image": "amazon/aws-xray-daemon",
  "essential": true,
  "portMappings": [
    {
      "containerPort": 2000,
      "hostPort": 2000,
      "protocol": "udp"
    }
  ]
}
```

## Cost Optimization

1. **Right-sizing Task Definitions**:
   - Monitor resource utilization
   - Adjust CPU and memory based on actual usage
   - Use Fargate Spot for non-critical workloads

2. **Auto Scaling**:
   - Implement target tracking scaling policies
   - Set up scheduled scaling for predictable workloads
   - Configure minimum and maximum service capacity

```bash
# Example of setting up target tracking scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/my-cluster/my-service \
  --policy-name cpu-tracking-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }'
```

3. **ECR Lifecycle Policies**:
   - Implement lifecycle policies to clean up unused images
   - Retain only necessary images to reduce storage costs

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only the last 10 production images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["prod"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Expire untagged images older than 14 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 14
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Troubleshooting Common Issues

1. **Deployment Failures**:
   - Check service events in ECS console
   - Verify task definition compatibility
   - Examine CloudWatch Logs for container startup issues

2. **Container Health Issues**:
   - Review health check configuration
   - Check for memory/CPU constraints
   - Analyze application logs for errors

3. **Pipeline Failures**:
   - Check CodeBuild/CodeDeploy logs
   - Verify IAM permissions
   - Validate build and deployment configurations

## References

- [AWS ECS Best Practices Guide](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)
- [Docker Documentation](https://docs.docker.com/)
- [AWS ECS Workshop](https://ecsworkshop.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
