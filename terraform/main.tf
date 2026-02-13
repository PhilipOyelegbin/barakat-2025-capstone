#============================================ Define Provider ============================================#
terraform {
  required_version = ">= 1.14.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket  = "project-bedrock-remote-state"
    key     = "project-bedrock-terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = var.project_tag
    }
  }
}

#============================================ Deployment Infrastructure ============================================#
# Provision IAM roles via EKS IAM module
module "eks_iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  project_tag  = var.project_tag
}

# Provision vpc infrastructure via Network module
module "network" {
  source       = "./modules/vpc"
  project_name = var.project_name
  project_tag  = var.project_tag
}

# Provision EKS infrastructure via Kubernetes module
module "kubernetes" {
  source               = "./modules/eks"
  project_name         = var.project_name
  project_tag          = var.project_tag
  aws_region           = var.aws_region
  vpc_id               = module.network.output_details.id
  private_subnet_ids   = module.network.output_details.private_subnet_id
  private_subnet_cidrs = module.network.output_details.private_subnet_cidrs
  cluster_iam_role_arn = module.eks_iam.iam_roles.eks_cluster_arn
  node_iam_role_arn    = module.eks_iam.iam_roles.eks_node_group_arn
  terraform_role_arn   = var.terraform_role_arn
}

module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  project_tag  = var.project_tag
}
