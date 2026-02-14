#============================================ Variables ============================================#
variable "project_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "project_tag" {
  description = "Value of the tag Project"
  type        = string
}

variable "aws_region" {
  description = "AWS region for EKS deployment"
  type        = string
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

# IAM inputs
variable "cluster_iam_role_arn" {
  description = "ARN of IAM role for EKS cluster"
  type        = string
}

variable "node_iam_role_arn" {
  description = "ARN of IAM role for EKS nodes"
  type        = string
}

variable "terraform_role_arn" {
  description = "ARN of IAM role for Terraform"
  type        = string
}

# Node configuration
variable "node_instance_types" {
  description = "List of EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}
