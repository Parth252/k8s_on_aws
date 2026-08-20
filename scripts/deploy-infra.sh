#!/usr/bin/env bash
set -euo pipefail

# Deploys a Terraform stack using values from the ignored root config.yaml.
# Usage: ./scripts/deploy-infra.sh <networking|compute> [plan|apply|destroy]

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
config_file="$repo_root/config.yaml"

if [[ $# -lt 1 || $# -gt 2 || ( "$1" != "networking" && "$1" != "compute" ) ]]; then
  echo "Usage: $0 <networking|compute> [plan|apply|destroy]" >&2
  exit 1
fi

stack="$1"
action="${2:-plan}"
generated_values_file="$repo_root/.generated/$stack.values.tfvars.json"

case "$action" in
  plan|apply|destroy) ;;
  *)
    echo "Action must be plan, apply, or destroy." >&2
    exit 1
    ;;
esac

if [[ ! -f "$config_file" ]]; then
  echo "Missing $config_file. Copy config.yaml.example first." >&2
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "yq v4 is required to read config.yaml. Install it, then try again." >&2
  exit 1
fi

# Terraform reads variable files only after backend initialization. yq reads the
# three backend values, then generates a Terraform JSON variable file from the
# same YAML configuration. No values are passed through environment variables.
aws_region="$(yq -er '.aws.region' "$config_file")"
state_bucket="$(yq -er '.aws.state_bucket.name' "$config_file")"
state_key_prefix="$(yq -er '.aws.state_bucket.key_prefix' "$config_file")"

mkdir -p "$(dirname "$generated_values_file")"
if [[ "$stack" == "networking" ]]; then
  yq '{
    "aws_region": .aws.region,
    "state_bucket": .aws.state_bucket.name,
    "state_key_prefix": .aws.state_bucket.key_prefix,
    "project_name": .project.name
  }' "$config_file" > "$generated_values_file"
else
  yq '{
    "aws_region": .aws.region,
    "state_bucket": .aws.state_bucket.name,
    "state_key_prefix": .aws.state_bucket.key_prefix,
    "project_name": .project.name,
    "control_plane_instance_type": .aws.compute.control_plane.instance_type,
    "worker_instance_type": .aws.compute.worker.instance_type,
    "root_volume_size": .aws.compute.root_volume_size
  }' "$config_file" > "$generated_values_file"
fi

stack_dir="infrastructure/$stack"
state_key="$state_key_prefix/$stack/terraform.tfstate"

terraform -chdir="$repo_root/$stack_dir" init \
  -backend-config="bucket=$state_bucket" \
  -backend-config="key=$state_key" \
  -backend-config="region=$aws_region" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform -chdir="$repo_root/$stack_dir" "$action" -var-file="$generated_values_file"
