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
./scripts/deploy-infra.sh networking plan
./scripts/deploy-infra.sh networking apply
```

Create the ignored `config.yaml` from `config.yaml.example` before running the
script. The script uses yq v4 to generate the Terraform values file. Terraform
state and local values are intentionally ignored by Git.
