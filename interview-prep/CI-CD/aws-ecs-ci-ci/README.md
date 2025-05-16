🚀 Step-by-Step: CI/CD Pipeline for Dockerized Node.js App on ECS
1️⃣ Prepare Your Node.js App Dockerfile
Make sure you have a Dockerfile like this at the root:

Dockerfile
Copy
Edit
FROM node:18

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
2️⃣ Create Amazon ECR Repository
Run in your AWS CLI or console:

bash
Copy
Edit
aws ecr create-repository --repository-name node-app --region us-east-1
3️⃣ Create ECS Cluster and Task Definition
In AWS Console, create an ECS cluster (choose Fargate or EC2 launch type).

Create an ECS Task Definition:

Define container with image URI (placeholder for now)

Container port: 3000

Create an ECS Service linked to your cluster and ALB (set desired count, e.g. 2)

Create an Application Load Balancer with HTTPS listener and target group pointing to ECS service

4️⃣ GitHub Actions Workflow: Build, Push, and Deploy
Create .github/workflows/deploy.yml in your repo:

yaml
Copy
Edit
name: Deploy to ECS

on:
  push:
    branches:
      - main

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: node-app
  ECS_CLUSTER: your-ecs-cluster-name
  ECS_SERVICE: your-ecs-service-name
  TASK_DEFINITION_FAMILY: your-task-def-family

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build Docker image
        run: |
          docker build -t $ECR_REPOSITORY:$GITHUB_SHA .
          docker tag $ECR_REPOSITORY:$GITHUB_SHA ${{ steps.ecr-login.outputs.registry }}/$ECR_REPOSITORY:$GITHUB_SHA

      - name: Push Docker image
        run: |
          docker push ${{ steps.ecr-login.outputs.registry }}/$ECR_REPOSITORY:$GITHUB_SHA

      - name: Create new ECS Task Definition revision
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ecs-task-def.json
          container-name: node-app-container
          image: ${{ steps.ecr-login.outputs.registry }}/$ECR_REPOSITORY:$GITHUB_SHA

      - name: Deploy to ECS service
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          cluster: ${{ env.ECS_CLUSTER }}
          service: ${{ env.ECS_SERVICE }}
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          wait-for-service-stability: true
Notes:
ecs-task-def.json is your base ECS Task Definition JSON file (downloaded from AWS Console and saved in repo)

Replace:

your-ecs-cluster-name

your-ecs-service-name

your-task-def-family

Use GITHUB_SHA as image tag to version each build uniquely

GitHub Secrets must contain AWS credentials with permissions to ECS, ECR, and ALB

5️⃣ Example ecs-task-def.json
json
Copy
Edit
{
  "family": "your-task-def-family",
  "networkMode": "awsvpc",
  "executionRoleArn": "arn:aws:iam::<account-id>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "node-app-container",
      "image": "PLACEHOLDER",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "cpu": "256",
  "memory": "512"
}
6️⃣ Setup AWS IAM Roles and Permissions
ECS Task Execution Role: Attach AmazonECSTaskExecutionRolePolicy

GitHub User / OIDC Role: Ensure it can push to ECR and deploy ECS services

7️⃣ Final Steps and Testing
Commit and push your code to trigger the workflow

Verify that ECS deploys your new task revision and updates service with zero downtime

ALB routes HTTPS traffic to your app containers
