variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_tag" {
  description = "Required project tag for all resources"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role for lambda execution"
  type = string
}