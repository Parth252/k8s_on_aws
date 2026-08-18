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

## Deploying infrastructure

Copy the safe template and add your own account-specific values:

```bash
cp config.yaml.example config.yaml
```

`config.yaml` is organized under `project` and `aws`: region, state bucket,
control-plane sizing, worker sizing, and shared compute storage. It is
deliberately ignored by Git. Do not put AWS
credentials in it; authenticate with your AWS CLI profile, IAM Identity Center,
or environment credentials.

The deploy script uses [yq v4](https://github.com/mikefarah/yq) to generate
ignored, stack-specific Terraform values files from `config.yaml`, initializes
the S3 backend with the same values, enables native S3 locking, then runs the
requested Terraform command:

```bash
./scripts/deploy-infra.sh networking plan
./scripts/deploy-infra.sh networking apply
./scripts/deploy-infra.sh compute plan
./scripts/deploy-infra.sh compute apply
```

Networking must be applied before compute. The default state keys are
`k8s-on-aws/networking/terraform.tfstate` and
`k8s-on-aws/compute/terraform.tfstate`; change the prefix locally if desired.

## Public-repository safety

Never commit Terraform state, `config.yaml`, generated values files, `*.tfvars`, access keys,
private keys, account IDs, S3 bucket names, SSM parameter paths, or other
personal values. The included `.gitignore` excludes local Terraform inputs.
