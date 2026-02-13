#!/bin/bash
set -e

echo "========================================="
echo "Project Bedrock - Complete Deployment"
echo "========================================="

echo -e "\n[1/3] Deploying Infrastructure with Terraform..."
cd terraform
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
cd ..

echo -e "\n[2/3] Configuring kubectl..."
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster

echo -e "\n[3/3] Deploying Retail Store Application..."
chmod +x scripts/deploy-app.sh
scripts/deploy-app.sh

echo -e "\n[4/4] Generating grading data..."
cd terraform
terraform output -json > ../grading.json
cd ..

echo "========================================="
echo "DEPLOYMENT COMPLETE!"
echo "========================================="
echo ""
echo "Access Key ID for bedrock-dev-view:"
terraform -chdir=terraform output -raw developer_access_key_id
echo ""
echo "To access the application:"
echo "kubectl port-forward svc/retail-store-app-ui -n retail-app 8080:80"
echo "Then open: http://localhost:8080"
echo ""
echo "To verify developer access:"
echo "aws configure --profile bedrock-dev"
echo "Then use kubectl with AWS auth"