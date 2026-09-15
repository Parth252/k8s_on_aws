script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

chmod +x "$repo_root/scripts/*.sh"
./scripts/deploy-tf-stack.sh networking auto-approve
./scripts/deploy-tf-stack.sh compute auto-approve
./scripts/deploy-tf-stack.sh k8s auto-approve