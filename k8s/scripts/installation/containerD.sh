#!/bin/bash
set -euo pipefail
VERSION="$1"
echo "============================================================="
echo "Installing containerd version $VERSION"

curl -fL -o /tmp/containerd.tar.gz \
  "https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-amd64.tar.gz"

sudo tar Cxzvf /usr/local /tmp/containerd.tar.gz

echo "ContainerD version: $(containerd --version)"