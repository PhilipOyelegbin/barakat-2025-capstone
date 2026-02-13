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

Run the deployment script below to setup remote state and application infrastructure

```bash
chmod 740 script/*

./script/deploy-infra.sh
```

### Phase 2: Application Deployment

Run the command below to deploy the application using helm

```bash
aws eks --region us-east-1 update-kubeconfig --name project-bedrock-cluster
kubectl get nodes

# Add required Helm repositories
helm repo add eks https://aws.github.io/eks-charts
helm repo add aws-containers https://aws-containers.github.io/retail-store-sample-app
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=project-bedrock-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::YOUR_ACCOUNT_ID:role/project-bedrock-cluster-alb-controller-role \
  --set region=us-east-1 \
  --set vpcId=vpc-12345678

# Verify ALB controller is running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Install retail store app
helm install retail-store-app aws-containers/retail-store-sample-app \
  --namespace retail-app \
  --create-namespace

# Verify the app is running
kubectl get all -n retail-app
```

---
