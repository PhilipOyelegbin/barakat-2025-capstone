#!/bin/bash

set -e

echo "Setup remote state storage..."
cd terraform/remote
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
echo "Remote state completed"

echo "Setup application infrastructure..."
cd ..
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
echo "Application infrastructure completed"
