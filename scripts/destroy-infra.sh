#!/bin/bash

ASSET_BUCKET_NAME=bedrock-assets-altsoe0251574

echo "Destroying application..."
./scripts/destroy-app.sh

echo "Emptying bucket: $ASSET_BUCKET_NAME"
aws s3 rm s3://$ASSET_BUCKET_NAME --recursive
echo "Application removed"

echo "Destroying application infrastructure..."
cd terraform
terraform init
terraform destroy -auto-approve
echo "Application infrastructure removed"
