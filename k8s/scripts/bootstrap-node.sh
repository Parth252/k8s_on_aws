#!/bin/bash

set -euo pipefail
LOG_FILE="/var/log/bootstrap-node.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "Bootstrap started: $(date)"
echo "========================================"

echo "managing yum"

yum install -y jq yq

echo "Configuring environment"

source /etc/k8s_on_aws/infra-config
SCRIPT_DIR="/opt/k8s_on_aws/scripts"
CONFIG_FILE="/etc/k8s_on_aws/config.yaml"

mkdir -p "$SCRIPT_DIR"
aws s3 cp "s3://${SCRIPTS_BUCKET}/scripts/" "$SCRIPT_DIR/" --recursive
aws s3 cp "s3://${SCRIPTS_BUCKET}/config.yaml" "$CONFIG_FILE"
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
echo "Environment configuration complete"

echo "installations"

K8s_VERSION="v$(yq -er '.k8s.version' "$CONFIG_FILE")"
CONTAINERD_VERSION="$(yq -er '.k8s.CRI.containerD.version' "$CONFIG_FILE")"
RUNC_VERSION="$(yq -er '.k8s.CRI.runC.version' "$CONFIG_FILE")"

echo "common installations"

$SCRIPT_DIR/installation/kubectl.sh $K8s_VERSION
$SCRIPT_DIR/installation/kubeadm.sh $K8s_VERSION
$SCRIPT_DIR/installation/containerD.sh $CONTAINERD_VERSION
$SCRIPT_DIR/installation/runC.sh $RUNC_VERSION
$SCRIPT_DIR/installation/cni.sh

echo "Node specific installations"
echo "Node type: $NODE_TYPE"

if [[ "$NODE_TYPE" == "control-plane" ]]; then
    $SCRIPT_DIR/installation/kubelet.sh $K8s_VERSION
elif [[ "$NODE_TYPE" == "worker" ]]; then
    $SCRIPT_DIR/installation/kubelet.sh $K8s_VERSION
else
    echo "Unknown node type: $NODE_TYPE"    
fi