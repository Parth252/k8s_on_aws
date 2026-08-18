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
./scripts/deploy-infra.sh compute plan
./scripts/deploy-infra.sh compute apply
```

This directory reads networking outputs from remote S3 state. Create the ignored
`config.yaml` from `config.yaml.example` before running the script. The script
uses yq v4 to generate the Terraform values file.
