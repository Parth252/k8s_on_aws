#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/bootstrap-node.log"
CONFIG_FILE="/etc/k8s_on_aws/config.yaml"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "Bootstrap started: $(date)"
echo "========================================"
source /etc/k8s_on_aws/infra-config
SCRIPT_DIR="/opt/kubernetes/scripts"

mkdir -p "$SCRIPT_DIR"

aws s3 cp "s3://${SCRIPTS_BUCKET}/scripts/" "$SCRIPT_DIR/" --recursive
aws s3 cp "s3://${SCRIPTS_BUCKET}/config.yaml" "$CONFIG_FILE"

find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

"$SCRIPT_DIR/installation/kubectl.sh"
# "$SCRIPT_DIR/installation/containerd.sh"