#!/bin/bash

echo "Deploying Retail Store Sample Application..."

# Create namespace if not exists
# kubectl create namespace retail-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy using Helm
helm upgrade --install retail-store-app \
  retail-store/retail-store-sample-app \
  --namespace retail-app \
  --values kubernetes/helm-values/retail-store-values.yaml \
  --wait \
  --timeout 10m

echo "Application deployment initiated..."
echo "Checking deployment status..."

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n retail-app --timeout=300s

echo "Listing all deployed resources:"
kubectl get all -n retail-app

echo "Application deployed successfully!"
echo "To access the application, use port-forward:"
echo "kubectl port-forward svc/ui-service -n retail-app 8080:80"