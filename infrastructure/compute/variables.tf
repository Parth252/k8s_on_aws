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

variable "control_plane_instance_type" {
  description = "Instance type for every control-plane node."
  type        = string
  default     = "t3a.small"
}

variable "worker_instance_type" {
  description = "Instance type for every worker node."
  type        = string
  default     = "t3a.small"
}

variable "root_volume_size" {
  description = "Size, in GiB, of each encrypted gp3 root volume."
  type        = number
  default     = 20
}

variable "private_domain_name" {
  description = "Route53 zone name for the Kubernetes DNS zone."
  type        = string
  default     = "k8s.internal"
}

variable "tags" {
  description = "Additional non-sensitive tags to apply to all resources."
  type        = map(string)
  default     = {}
}
