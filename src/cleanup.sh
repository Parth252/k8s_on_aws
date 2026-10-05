#!/bin/bash
set -euo pipefail
./scripts/deploy-tf-stack.sh k8s auto-destroy
./scripts/deploy-tf-stack.sh compute auto-destroy
./scripts/deploy-tf-stack.sh networking auto-destroy

#figure out repo root