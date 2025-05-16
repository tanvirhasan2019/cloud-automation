# AWS ECS CI/CD Pipeline with GitHub Actions

This repository contains an automated CI/CD pipeline that builds, tests, and deploys your application to AWS Elastic Container Service (ECS) using GitHub Actions.

## Features

- Automated building and testing
- Docker image creation with security scanning
- Deployment to AWS ECS
- Environment-specific deployments (dev/staging/prod)
- Slack notifications

## Code Files

### GitHub Actions Workflow (.github/workflows/aws-ecs-deploy.yml)

```yaml
name: AWS ECS Deploy

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

env:
  AWS_REGION: us-east-1                   # Set your AWS region
  ECR_REPOSITORY: my-app-repo             # Set your ECR repository name
  ECS_SERVICE: my-app-service             # Set your ECS service name
  ECS_CLUSTER: my-app-cluster             # Set your ECS cluster name
  CONTAINER_NAME: app                     # Set the container name in task definition
  TASK_DEFINITION: task-definition.json   # Path to task definition file

jobs:
  # Build and test the application
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16'
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run linting
      run: npm run lint
      
    - name: Run tests
      run: npm test
      
    - name: Build application
      run: npm run build

  # Build and push Docker image to ECR
  build-and-push:
    name: Build and Push to ECR
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
      
    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Build Docker image
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
        
        # Run security scan on built image
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest --exit-code 1 --severity HIGH,CRITICAL $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        
        # Push image to ECR
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        
        echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
        
    - name: Fill in the new image ID in the Amazon ECS task definition
      id: task-def
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.TASK_DEFINITION }}
        container-name: ${{ env.CONTAINER_NAME }}
        image: ${{ steps.build-image.outputs.image }}
        
    - name: Export rendered task definition
      run: |
        echo '${{ steps.task-def.outputs.task-definition }}' > rendered-task-definition.json
        
    - name: Upload rendered task definition
      uses: actions/upload-artifact@v3
      with:
        name: task-definition
        path: rendered-task-definition.json

  # Deploy to ECS
  deploy:
    name: Deploy to ECS
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Download task definition
      uses: actions/download-artifact@v3
      with:
        name: task-definition
        
    - name: Deploy Amazon ECS task definition
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: rendered-task-definition.json
        service: ${{ env.ECS_SERVICE }}
        cluster: ${{ env.ECS_CLUSTER }}
        wait-for-service-stability: true
        
    - name: Post-deployment verification
      run: |
        aws ecs describe-services --cluster ${{ env.ECS_CLUSTER }} --services ${{ env.ECS_SERVICE }} --query 'services[0].deployments' --output json
        echo "Deployment completed successfully!"

  # Notify on deployment completion
  notify:
    name: Notify Deployment Status
    needs: deploy
    runs-on: ubuntu-latest
    if: always()
    
    steps:
    - name: Send Slack notification
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ needs.deploy.result }}
        fields: repo,message,commit,author,action,eventName,workflow
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
      if: ${{ env.SLACK_WEBHOOK_URL != '' }}
```

### Task Definition (task-definition.json)

```json
{
  "family": "my-app",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789012:secret:app/db/password:password::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:8080/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

### Dockerfile Example

```dockerfile
FROM node:16-alpine as builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and build application
COPY . .
RUN npm run build

# Production stage
FROM node:16-alpine

WORKDIR /app

# Copy only necessary files from build stage
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Run as non-root user for better security
USER node

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8080

# Expose the application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# Start the application
CMD ["node", "dist/main.js"]
```

## Setup Instructions

### Prerequisites

1. AWS resources:
   - ECS cluster and service
   - ECR repository
   - IAM roles for task execution and tasks

2. GitHub repository with your application code

### Configuration Steps

1. **Set up GitHub Secrets**
   
   Add these secrets to your repository (Settings → Secrets → Actions):
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `SLACK_WEBHOOK_URL` (optional): For deployment notifications

2. **Add Files to Your Repository**
   
   - `.github/workflows/aws-ecs-deploy.yml`: GitHub Actions workflow definition
   - `task-definition.json`: ECS task definition template
   - Ensure your `Dockerfile` is in the repository root

3. **Update Configuration Variables**
   
   In `aws-ecs-deploy.yml`, modify these environment variables:
   - `AWS_REGION`: Your AWS region (e.g., us-east-1)
   - `ECR_REPOSITORY`: Your ECR repository name
   - `ECS_SERVICE`: Your ECS service name  
   - `ECS_CLUSTER`: Your ECS cluster name
   - `CONTAINER_NAME`: Container name in your task definition
   - `TASK_DEFINITION`: Path to your task definition file

4. **Update Task Definition**
   
   In `task-definition.json`, update:
   - ARN references to match your AWS account
   - Resource allocations (CPU/memory)
   - Container configurations

## How to Use

### Automatic Deployments

- Push to main/master branches to trigger automatic build and deployment to dev environment

### Manual Deployments

1. Go to Actions tab in your repository
2. Select "AWS ECS Deploy" workflow
3. Click "Run workflow"
4. Select environment (dev/staging/prod)
5. Click "Run workflow"

## Workflow Process

1. **Build & Test**: Runs linting and tests
2. **Build & Push**: Creates Docker image, scans for vulnerabilities, pushes to ECR
3. **Deploy**: Updates ECS task definition, deploys to selected environment
4. **Notify**: Sends Slack notification about deployment status

## Customization

- Add environment-specific configurations in the workflow file
- Implement blue/green deployments via AWS CodeDeploy
- Add pull request validation without deployment

## Troubleshooting

If deployment fails:
1. Check GitHub Actions logs for error details
2. Verify AWS credentials and permissions
3. Confirm ECS service and cluster configuration
4. Review task definition for errors
