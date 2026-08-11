variable "aws_region" {
  description = "AWS Region in which to create the learning cluster network."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix applied to resource names and tags."
  type        = string
  default     = "k8s-learning"
}

variable "vpc_cidr" {
  description = "CIDR block for the cluster VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Three non-overlapping CIDR blocks, one for each Availability Zone."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 3
    error_message = "Provide exactly three public subnet CIDR blocks."
  }
}

variable "tags" {
  description = "Additional non-sensitive tags to apply to all resources."
  type        = map(string)
  default     = {}
}
