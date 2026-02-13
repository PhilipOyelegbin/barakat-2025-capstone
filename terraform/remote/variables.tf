variable "project_name" {
  description = "The project name"
  type        = string
  default     = "project-bedrock"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
