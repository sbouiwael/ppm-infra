#!/usr/bin/env bash
# Bootstraps the local env via Terraform.
# Assumes a working kubeconfig (run scripts/minikube-up.sh first if you don't have one).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_DIR="$HERE/terraform/envs/local"

cd "$ENV_DIR"

if [ ! -f .terraform.lock.hcl ]; then
  echo "==> terraform init"
  terraform init -upgrade
fi

echo "==> terraform apply"
terraform apply -auto-approve

echo
echo "==> Bootstrap complete. Argo CD will now sync the GitOps repo."
echo "    Run 'kubectl get applications -n argocd -w' to watch progress."
