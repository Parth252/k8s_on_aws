#core

variable "aws_region" {
  description = "AWS Region used by the networking stack."
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket" {
  description = "Private S3 bucket name holding Terraform state. Supply it in the ignored infra-values.tfvars file."
  type        = string
}

variable "state_key_prefix" {
  description = "S3 key prefix for this project's Terraform state."
  type        = string
}

variable "project_name" {
  description = "Prefix applied to resource names and tags."
  type        = string
  default     = "k8s-learning"
}

variable "tags" {
  description = "Additional non-sensitive tags to apply to all resources."
  type        = map(string)
  default     = {}
}

locals {
  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "Terraform"
      stack     = "k8s"
    },
    var.tags,
  )
}
#params

variable "k8s_version" {
  description = "Kubernetes version to deploy."
  type        = string
}