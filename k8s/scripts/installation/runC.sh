#!/bin/bash
set -euo pipefail
VERSION=$1
echo "============================================================="
echo "Installing runC version $VERSION"

curl -fL \
  "https://github.com/opencontainers/runc/releases/download/v${VERSION}/runc.amd64" \
  -o /tmp/runc

sudo install -m 755 /tmp/runc /usr/local/sbin/runc