#!/usr/bin/env bash
set -euo pipefail

# Deploys a Terraform stack using values from the ignored root config.yaml.
# Usage: ./scripts/deploy-infra.sh <networking|compute|k8s> [plan|apply|destroy]

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
config_file="$repo_root/config.yaml"

if [[ $# -lt 1 || $# -gt 2 || ( "$1" != "networking" && "$1" != "compute" && "$1" != "k8s" ) ]]; then
  echo "Usage: $0 <networking|compute|k8s> [plan|apply|destroy]" >&2
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

#Backend values
aws_region="$(yq -er '.aws.region' "$config_file")"
state_bucket="$(yq -er '.aws.state_bucket.name' "$config_file")"
state_key_prefix="$(yq -er '.aws.state_bucket.key_prefix' "$config_file")"

mkdir -p "$(dirname "$generated_values_file")"

declare -A stack_dirs=(
  [networking]="$repo_root/infrastructure/networking"
  [compute]="$repo_root/infrastructure/compute"
  [k8s]="$repo_root/k8s"
)
stack_dir="${stack_dirs[$stack]}"

mapping_expression="$(cat "$stack_dir/config-file-mapping.yq")"
echo "Using mapping expression: $mapping_expression"

yq "$mapping_expression" "$config_file" > "$generated_values_file"
state_key="$state_key_prefix/$stack/terraform.tfstate"

terraform -chdir="$stack_dir" init \
  -backend-config="bucket=$state_bucket" \
  -backend-config="key=$state_key" \
  -backend-config="region=$aws_region" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

terraform -chdir="$stack_dir" "$action" -var-file="$generated_values_file"
