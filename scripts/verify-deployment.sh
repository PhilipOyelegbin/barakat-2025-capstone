#!/bin/bash

echo "Verifying Retail Store Application Deployment..."

# Check namespace exists
echo "1. Checking namespace..."
kubectl get namespace retail-app

# Check all pods are running
echo -e "\n2. Checking pods status..."
kubectl get pods -n retail-app

# Check services
echo -e "\n3. Checking services..."
kubectl get services -n retail-app

# Check deployments
echo -e "\n4. Checking deployments..."
kubectl get deployments -n retail-app

# Check Helm release
echo -e "\n5. Checking Helm release..."
helm list -n retail-app

# Test application connectivity
echo -e "\n6. Testing application connectivity..."
UI_POD=$(kubectl get pods -n retail-app -l app.kubernetes.io/component=ui -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$UI_POD" ]; then
  echo "UI Pod: $UI_POD"
  kubectl exec -n retail-app $UI_POD -- curl -s -o /dev/null -w "%{http_code}" http://localhost:80
  echo " - HTTP Status Code"
else
  echo "UI pod not found yet. Wait for deployment to complete."
fi

echo -e "\nVerification complete!"