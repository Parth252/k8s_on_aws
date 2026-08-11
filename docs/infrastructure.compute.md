# Compute

Creates three control-plane nodes and three worker nodes after the networking
stack has been applied. All use Amazon Linux 2023 on x86_64 and have an IAM
instance profile for AWS Systems Manager Session Manager.

No SSH key pair or inbound SSH rule is configured. Connect from a configured
local AWS CLI with:

```bash
aws ssm start-session --target INSTANCE_ID --region ap-south-1
```

The Session Manager plugin must be installed on the computer running the command.

## Apply

Apply `../networking` first, then:

```bash
terraform init
terraform plan
terraform apply
```

This directory reads the local networking state for learning purposes. State is
ignored by Git. Before collaborating or automating deployments, migrate both
stacks to an encrypted remote backend.
