# Node Todo App

A containerized Express.js todo application with automated CI/CD using GitHub Actions for deployment to AWS ECR and ECS.

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Local Development](#local-development)
  - [Docker Development](#docker-development)
- [Application Structure](#application-structure)
- [CI/CD Pipeline](#ci-cd-pipeline)
  - [Workflow Overview](#workflow-overview)
  - [GitHub Secrets](#github-secrets)
- [Deployment Architecture](#deployment-architecture)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Project Overview

This project is a simple todo list application built with Node.js and Express. It demonstrates a complete CI/CD pipeline that automatically builds, tests, and deploys the application to AWS using Docker containers.

### Key Features

- RESTful API for todo management
- Containerized with Docker
- Automated CI/CD with GitHub Actions
- Deployment to AWS ECR and ECS
- Security best practices

## Prerequisites

- Node.js (v16+)
- Docker and Docker Compose
- AWS Account with appropriate permissions
- GitHub Account
- AWS CLI (configured with appropriate credentials)

## Getting Started

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/node-todo-app.git
   cd node-todo-app
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Access the application at `http://localhost:3000`

### Docker Development

1. Build and run the Docker container:
   ```bash
   docker-compose up --build
   ```

2. Access the application at `http://localhost:3000`

## Application Structure

```
node-todo-app/
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml       # GitHub Actions workflow file
│
├── src/
│   ├── controllers/        # Route controllers
│   ├── models/             # Data models
│   ├── routes/             # API routes
│   ├── middleware/         # Express middleware
│   ├── config/             # Configuration files
│   └── app.js              # Express application setup
│
├── tests/                  # Test files
├── .dockerignore           # Docker ignore file
├── .gitignore              # Git ignore file
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose configuration
├── package.json            # Node.js dependencies
└── README.md               # Project documentation
```

## CI/CD Pipeline

### Workflow Overview

The CI/CD pipeline is implemented using GitHub Actions and consists of the following stages:

1. **Build and Test**:
   - Checkout code
   - Install dependencies
   - Run linting and tests
   - Build Docker image

2. **Security Scanning**:
   - Scan code for vulnerabilities
   - Scan Docker image

3. **Deployment**:
   - Push Docker image to ECR
   - Update ECS service

### GitHub Secrets

The following GitHub Secrets are required for the CI/CD pipeline:

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for deployment |
| `AWS_REGION` | AWS region for deployment (e.g., `us-east-1`) |
| `ECR_REPOSITORY` | Name of the ECR repository |
| `ECS_CLUSTER` | Name of the ECS cluster |
| `ECS_SERVICE` | Name of the ECS service |
| `ECS_TASK_DEFINITION` | Path to the ECS task definition file |
| `CONTAINER_NAME` | Name of the container in the task definition |

## Deployment Architecture

```
                            ┌─────────────┐
                            │  GitHub     │
                            │  Actions    │
                            └──────┬──────┘
                                   │
                                   ▼
┌─────────────┐          ┌─────────────────┐
│             │          │                 │
│  GitHub     │──Push───▶│  AWS ECR        │
│  Repository │          │  (Container     │
│             │          │   Registry)     │
└─────────────┘          └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │                 │
                         │  AWS ECS        │
                         │  (Container     │
                         │   Orchestration)│
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │                 │
                         │  Application    │
                         │  Load Balancer  │
                         │                 │
                         └─────────────────┘
```

## Best Practices

### CI/CD Best Practices

1. **Trunk-based Development**:
   - Work in small, frequent commits
   - Merge to main branch frequently

2. **Environment Separation**:
   - Use different environments for development, staging, and production
   - Configure environment-specific variables

3. **Security**:
   - Store all sensitive information in GitHub Secrets
   - Implement least privilege access principles
   - Regularly rotate access keys

4. **Testing**:
   - Implement unit, integration, and end-to-end tests
   - Ensure tests run before deployment

5. **Monitoring and Logging**:
   - Implement application monitoring
   - Set up alerts for critical errors

### Docker Best Practices

1. **Use Multi-stage Builds**:
   - Reduce final image size
   - Improve security by excluding build tools

2. **Follow Least Privilege Principle**:
   - Run containers as non-root users
   - Use read-only file systems where possible

3. **Layer Optimization**:
   - Order Dockerfile instructions to maximize caching
   - Combine RUN commands to reduce layers

4. **Security Scanning**:
   - Regularly scan images for vulnerabilities
   - Keep base images updated

## Troubleshooting

### Common Issues

1. **Pipeline Failures**:
   - Check GitHub Actions logs for detailed error messages
   - Verify GitHub Secrets are correctly configured

2. **Deployment Issues**:
   - Ensure AWS credentials have sufficient permissions
   - Check ECS service events for deployment failures

3. **Application Issues**:
   - Check container logs in ECS
   - Verify environment variables are correctly set

### Getting Help

If you encounter issues, please open a GitHub issue with the following information:
- Description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Any error messages or logs