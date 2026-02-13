variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "project_tag" {
  description = "Value of the tag Project"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.8.0.0/16"
}

variable "pub_cidr_block" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.8.1.0/24", "10.8.2.0/24"]
}

variable "priv_cidr_block" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.8.3.0/24", "10.8.4.0/24"]
}
