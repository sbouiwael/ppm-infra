#!/usr/bin/env bash
# Print the Argo CD initial admin password.
set -euo pipefail
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
echo
