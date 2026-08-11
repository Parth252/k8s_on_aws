# Networking

Creates the network shared by the Kubernetes nodes:

- one VPC;
- three public subnets in separate Availability Zones;
- an Internet Gateway and public route table;
- a node security group with no inbound rules.

Nodes receive public IPv4 addresses only to obtain outbound internet access for
SSM, operating-system packages, and container images. The security group has no
inbound rules, so those addresses do not expose SSH or Kubernetes services.

## Apply

```bash
terraform init
terraform plan
terraform apply
```

Terraform state and `terraform.tfvars` are intentionally ignored by Git. Never
commit access keys, private keys, account IDs, state files, or local variable
files.
