#!/bin/bash
set -euo pipefail
K8s_VERSION="$1"
echo "============================================================="
echo "starting kubectl installation"

curl -LO https://dl.k8s.io/release/$K8s_VERSION/bin/linux/amd64/kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

echo "kubectl installation completed"   