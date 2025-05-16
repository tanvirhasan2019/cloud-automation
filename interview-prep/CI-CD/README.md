# 🚀 CI/CD Interview Preparation Guide

This guide is designed to help you prepare for DevOps and Cloud Engineering interviews with a strong focus on **CI/CD pipelines**, particularly using **GitHub Actions, GitLab CI, Jenkins**, and **CircleCI**.

---

## 📘 Table of Contents

- [Overview](#overview)
- [CI/CD Fundamentals](#cicd-fundamentals)
- [Tool Comparison](#tool-comparison)
- [Common Interview Questions](#common-interview-questions)
- [Practical YAML Examples](#practical-yaml-examples)
- [Hands-On Tasks](#hands-on-tasks)
- [Final Tips](#final-tips)

---

## 🧠 Overview

Continuous Integration and Continuous Deployment (CI/CD) are key practices in modern DevOps. Mastery of CI/CD tools and concepts is essential for DevOps engineers, especially in cloud-native environments.

This guide covers:

- Core CI/CD concepts
- Differences between popular tools
- Sample questions and answers
- Real-world scenarios
- Hands-on practice tasks

---

## 🧱 CI/CD Fundamentals

- **CI (Continuous Integration):** Automatically integrating code and running tests on push or PR.
- **CD (Continuous Deployment/Delivery):** Automatically deploying tested code to staging or production.
- **Pipeline Stages:** Build → Test → Deploy
- **Triggers:** Git events (push, pull_request), schedules, or manual approvals
- **Runners/Agents:** Execute jobs (GitHub-hosted, self-hosted, etc.)
- **Secrets Management:** Secure storage for tokens and keys
- **Artifacts vs Cache:**
  - **Artifacts**: Store build results (binaries, reports)
  - **Cache**: Store reusable files (like dependencies) to speed up builds

---

## ⚙️ Tool Comparison

| Feature             | GitHub Actions         | GitLab CI/CD            | Jenkins                  | CircleCI                 |
|---------------------|------------------------|--------------------------|---------------------------|--------------------------|
| Config Format       | YAML (`.github/workflows`) | YAML (`.gitlab-ci.yml`) | Groovy / Declarative      | YAML (`.circleci/config.yml`) |
| Integration         | Native with GitHub     | Native with GitLab       | External setup            | GitHub/Bitbucket         |
| Plugins             | GitHub Marketplace     | Docker & Shell Exec      | Extensive ecosystem       | Limited                  |
| Hosting             | GitHub-hosted/Self     | GitLab-hosted/Self       | Self-hosted or Cloud      | Cloud-native             |

---

## ❓ Common Interview Questions

### 1. **What is CI/CD and why is it important?**
> CI/CD improves code quality and deployment speed by automating the build, test, and deployment process.

### 2. **How do GitHub Actions and GitLab CI differ?**
> GitHub Actions is tightly integrated with GitHub and uses workflows defined in `.github/workflows`. GitLab CI uses `.gitlab-ci.yml` and supports native Docker builds.

### 3. **How are secrets managed?**
> In GitHub/GitLab, secrets are stored in repo settings and injected as environment variables. In Jenkins, use the Credentials Plugin.

### 4. **What’s the difference between cache and artifact?**
> Cache speeds up builds by reusing dependencies. Artifacts store outputs like reports or binaries for use in later steps or stages.

### 5. **Describe a CI/CD failure you've resolved.**
> Talk about real-world experience: what failed, how you diagnosed it, and how you resolved or improved the pipeline afterward.

---

## 🛠️ Practical YAML Examples

### GitHub Actions (Basic Node.js Build)
```yaml
name: CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm install
      - run: npm test
