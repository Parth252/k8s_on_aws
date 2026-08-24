#!/bin/bash

set -euo pipefail

SSH_DIR="/home/ec2-user/.ssh"
PRIVATE_KEY="$SSH_DIR/k8s_cluster"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Public key — allows cluster nodes to SSH into this node
cat > "$SSH_DIR/authorized_keys" <<'KEY'
${SSH_PUBLIC_KEY}
KEY

# Private key — allows this node to SSH into other cluster nodes
cat > "$PRIVATE_KEY" <<'PRIVATE_KEY'
${SSH_PRIVATE_KEY}
PRIVATE_KEY

# SSH client configuration
cat > "$SSH_DIR/config" <<'SSH_CONFIG'
${SSH_CONFIG}
SSH_CONFIG

# Set ownership
chown -R ec2-user:ec2-user "$SSH_DIR"

# Set permissions
chmod 600 "$SSH_DIR/authorized_keys"
chmod 600 "$PRIVATE_KEY"
chmod 600 "$SSH_DIR/config"

echo "SSH cluster configuration complete."