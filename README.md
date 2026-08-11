# Kubernetes on AWS

A hands-on Terraform project for learning how to build a Kubernetes cluster on
EC2 from scratch. This project deliberately starts with the AWS infrastructure;
Kubernetes bootstrapping and Go automation come later.

## Infrastructure

- `infrastructure/networking`: VPC, public subnets, routing, and node security
  group.
- `infrastructure/compute`: SSM-enabled EC2 control-plane and worker nodes.

Apply networking before compute. The initial cluster uses six `t3a.small`
instances in Mumbai (`ap-south-1`): three control-plane nodes and three workers.
Session Manager provides terminal access without exposing SSH.

## Public-repository safety

Never commit Terraform state, `*.tfvars`, access keys, private keys, account
IDs, or other personal values. The included `.gitignore` excludes these files;
use `terraform.tfvars.example` files only as safe templates.
