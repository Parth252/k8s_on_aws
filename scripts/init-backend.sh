#!/usr/bin/env bash
set -euo pipefail

# Initializes a state backend without writing a personal SSM path or bucket name
# into the repository. Required: TF_STATE_BUCKET_PARAMETER (SSM parameter path).
# Optional: AWS_REGION (defaults to ap-south-1).

if [[ $# -ne 1 || ( "$1" != "networking" && "$1" != "compute" ) ]]; then
  echo "Usage: $0 <networking|compute>" >&2
  exit 1
fi

if [[ -z "${TF_STATE_BUCKET_PARAMETER:-}" ]]; then
  echo "Set TF_STATE_BUCKET_PARAMETER to your private SSM parameter path first." >&2
  exit 1
fi

state_region="${AWS_REGION:-ap-south-1}"
state_bucket="$(aws ssm get-parameter \
  --name "$TF_STATE_BUCKET_PARAMETER" \
  --region "$state_region" \
  --query 'Parameter.Value' \
  --output text)"

export TF_VAR_terraform_state_bucket_name="$state_bucket"

terraform -chdir="infrastructure/$1" init \
  -backend-config="bucket=$state_bucket" \
  -backend-config="key=k8s-on-aws/$1/terraform.tfstate" \
  -backend-config="region=$state_region" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"
