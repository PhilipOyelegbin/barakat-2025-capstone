#!/bin/bash

# set -e

# Uninstall all Helm releases
echo "Uninstalling Retail Store Sample Application..."
aws eks --region us-east-1 update-kubeconfig --name project-bedrock-cluster
kubectl get nodes
kubectl get namespace retail-app

helm uninstall catalog -n retail-app
helm uninstall cart -n retail-app
helm uninstall orders -n retail-app
helm uninstall checkout -n retail-app
helm uninstall ui -n retail-app

helm list -n retail-app
echo "All Helm releases uninstalled."