variable "project_name" {
  description = "The project name"
  type        = string
}

variable "project_tag" {
  description = "Value of the tag Project"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "terraform_role_arn" {
  description = "ARN of IAM role for Terraform"
  type        = string
}
