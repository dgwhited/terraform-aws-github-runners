variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Leave as latest for initial deployment. Then update to set the correct image tag (not URI)."
}

variable "num_runners" {
  type        = number
  default     = 0
  description = "Set to 0 for initial deployment. Then scale once the runner image is available in the repo."
}

variable "github_org" {
  type        = string
  description = "organization"
}

variable "cpu" {
  type        = string
  description = "CPU allocation for runner containers. Be sure to match with memory!"
  default     = "4096"
}

variable "memory" {
  type        = string
  description = "Memory allocation for runner containers. Be sure to match with CPU!"
  default     = "8192"
}

variable "ecr_repo_name" {
  type        = string
  description = "Name for the ECR repo that will be created to hold runner custom image"
  default     = "github-runner-image"
}

variable "stack_name" {
  type        = string
  description = "Name of the stack/deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC to split into two equal parts for subnets."
}

variable "environment" {
  type        = string
  description = "Environment tag for the runner."
}
