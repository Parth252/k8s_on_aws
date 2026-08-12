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

## Private Terraform backend setup

The Terraform state bucket and the SSM parameter that names it are personal
infrastructure values, so they are deliberately not present in this repository.
In each terminal session, set these local values:

```bash
export AWS_REGION="ap-south-1"
export TF_STATE_BUCKET_PARAMETER="/your/private/terraform/state-bucket-name"
export TF_VAR_terraform_state_bucket_name="$(aws ssm get-parameter \
  --name "$TF_STATE_BUCKET_PARAMETER" \
  --region "$AWS_REGION" \
  --query 'Parameter.Value' \
  --output text)"
```

Initialize each stack through the helper. It fetches the bucket name locally and
enables Terraform's native S3 lockfile; no DynamoDB table is required.

```bash
./scripts/init-backend.sh networking
./scripts/init-backend.sh compute
```

The state keys are `k8s-on-aws/networking/terraform.tfstate` and
`k8s-on-aws/compute/terraform.tfstate`.

## Public-repository safety

Never commit Terraform state, `*.tfvars`, access keys, private keys, account
IDs, S3 bucket names, SSM parameter paths, or other personal values. The
included `.gitignore` excludes these files; use `terraform.tfvars.example` files
only as safe templates.
