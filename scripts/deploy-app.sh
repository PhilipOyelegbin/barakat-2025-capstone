#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage: $0 <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>"
  exit 1
fi

# Argument Variables
AWS_ACCESS_KEY_ID=$1
AWS_SECRET_ACCESS_KEY=$2
AWS_REGION=$3

echo "Deploying Retail Store Sample Application..."

aws eks --region us-east-1 update-kubeconfig --name project-bedrock-cluster
kubectl get nodes
kubectl get namespace retail-app

# Deploy all microservice using helm charts from ECR Public Gallery

# Deploy catalog service with its MySQL database
helm install catalog oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
--version 1.2.1 \
--namespace retail-app \
--set database.type=mysql \
--set database.host=catalog-mysql \
--set database.name=catalogdb \
--set database.user=catalog_user \
--set database.password=catalog_password \
--set mysql.database=catalogdb \
--set mysql.rootPassword=root_password \
--wait

# Deploy cart service with DynamoDB
helm install cart oci://public.ecr.aws/aws-containers/retail-store-sample-cart-chart \
--version 1.2.1 \
--namespace retail-app \
--set dynamodb.enabled=true \
--set dynamodb.tableName=cart-items-table \
--set dynamodb.region=$AWS_REGION \
--set dynamodb.accessKeyId=$AWS_ACCESS_KEY_ID \
--set dynamodb.secretAccessKey=$AWS_SECRET_ACCESS_KEY \
--set dynamodb.endpoint=https://dynamodb.$AWS_REGION.amazonaws.com \
--wait

# Deploy orders service with PostgreSQL
helm install orders oci://public.ecr.aws/aws-containers/retail-store-sample-orders-chart \
--version 1.2.1 \
--namespace retail-app \
--set postgresql.enabled=true \
--set postgresql.host=orders-postgresql \
--set postgresql.database=ordersdb \
--set postgresql.user=orders_user \
--set postgresql.password=orders_password \
--wait

# Deploy checkout service with Redis for session management
helm install checkout oci://public.ecr.aws/aws-containers/retail-store-sample-checkout-chart \
--version 1.2.1 \
--namespace retail-app \
--set redis.enabled=true \
--set redis.host=cart-redis \
--set redis.port=6379 \
--wait

# Deploy UI service - the frontend application
helm install ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
--version 1.2.1 \
--namespace retail-app \
--set catalogService.host=catalog \
--set cartService.host=cart \
--set ordersService.host=orders \
--set checkoutService.host=checkout \
--set service.type=LoadBalancer \
--set service.port=80 \
--set service.targetPort=80 \
--wait

echo "Application deployment initiated..."
echo "Checking deployment status..."

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n retail-app --timeout=300s

# Verify deployments
kubectl get pods -n retail-app
kubectl get svc -n retail-app
kubectl get deployments -n retail-app

# Check MySQL for catalog
kubectl get pods -n retail-app | grep catalog-mysql

# Check Redis for cart
kubectl get pods -n retail-app | grep cart-redis

# Check PostgreSQL for orders
kubectl get pods -n retail-app | grep orders-postgresql

# Verify ALB controller is running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# List all helm release
helm list -n retail-app

echo "Listing all deployed resources:"
kubectl get all -n retail-app

echo "Application deployed successfully!"