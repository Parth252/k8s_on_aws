variable "aws_region" {
  description = "AWS Region used by the networking stack."
  type        = string
  default     = "ap-south-1"
}

variable "terraform_state_bucket_name" {
  description = "Private S3 bucket name holding Terraform state. Supply it with TF_VAR_terraform_state_bucket_name; do not commit it."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Prefix applied to resource names and tags."
  type        = string
  default     = "k8s-learning"
}

variable "instance_type" {
  description = "Instance type for every node. t3a.small is the kubeadm minimum for this learning cluster."
  type        = string
  default     = "t3a.small"
}

variable "root_volume_size" {
  description = "Size, in GiB, of each encrypted gp3 root volume."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional non-sensitive tags to apply to all resources."
  type        = map(string)
  default     = {}
}
