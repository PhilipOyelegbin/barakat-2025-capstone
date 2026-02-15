# Capstone Project - Production-Grade Microservices on AWS EKS

As our new Cloud DevOps Engineer, you are entrusted with **"Project Bedrock."** Your mission is to provision our first production-grade Kubernetes environment on AWS and deploy the new Retail Store Application. This foundation will dictate our ability to deliver a world-class shopping experience.

**Objectives**

Your objective is to provision a secure Amazon EKS cluster and deploy the AWS Retail Store Sample App. You must automate the infrastructure, secure developer access, implement observability, and extend the architecture with event-driven serverless components.
Success looks like: A fully automated infrastructure pipeline, a running application, centralized logging, and a secured cluster ready for developer hand-off.

---

## Requirements

- Terraform v1.14.3
- AWS CLI

---

## Set up

### Phase 1: Infrastructure Deployment

- Clone the repo to your local machine

  ```bash
  git clone https://github.com/PhilipOyelegbin/barakat-2025-capstone.git

  cd barakat-2025-capstone
  ```

- Run the deployment script below to setup remote state and application infrastructure

  ```bash
  chmod 740 script/*

  ./script/deploy-infra.sh
  ```

### Phase 2: Application Deployment

- Run the command below to deploy the application using helm

  ```bash
  ./script/deploy-app.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>
  ```

> On successful deployment, open your browser and navigate to: http://localhost:8080

---
