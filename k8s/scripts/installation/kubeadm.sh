#!/bin/bash
set -euo pipefail
K8S_VERSION="$1"
echo "============================================================="
echo "Installing kubeadm version $K8S_VERSION"

curl -fL \
  "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubeadm" \
  -o /tmp/kubeadm

sudo install -m 755 /tmp/kubeadm /usr/local/bin/kubeadm

kubeadm version