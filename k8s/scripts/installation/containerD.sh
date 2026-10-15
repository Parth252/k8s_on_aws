#!/bin/bash
set -euo pipefail
VERSION="$1"
echo "============================================================="
echo "Installing containerd version $VERSION"

curl -fL -o /tmp/containerd.tar.gz \
  "https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-amd64.tar.gz"

sudo tar Cxzvf /usr/local /tmp/containerd.tar.gz

echo "ContainerD version: $(containerd --version)"

#start ContainerD service
echo "Installing containerd service"

sudo curl -fL \
  "https://raw.githubusercontent.com/containerd/containerd/v${VERSION}/containerd.service" \
  -o /etc/systemd/system/containerd.service
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i \
  's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

echo "Starting containerd service"

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

echo "ContainerD service status: $(systemctl is-active containerd)"
echo "ContainerD socket: $(ls -l /run/containerd/containerd.sock)"

echo "ContainerD installation completed"