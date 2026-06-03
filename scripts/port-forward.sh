#!/usr/bin/env bash
# Convenience: open the four most useful tunnels at once.
# Each runs in the background; press Ctrl-C to tear them all down.
set -euo pipefail

cleanup() {
  echo
  echo "==> Stopping port-forwards..."
  kill $(jobs -p) 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Argo CD UI    http://localhost:8080  (admin / see scripts/argocd-password.sh)"
kubectl -n argocd port-forward svc/argocd-server 8080:80 >/dev/null 2>&1 &

echo "==> Frontend      http://localhost:4200"
kubectl -n ppm-local port-forward svc/ppm-frontend 4200:80 >/dev/null 2>&1 &

echo "==> Backend API   http://localhost:8082/actuator/health"
kubectl -n ppm-local port-forward svc/ppm-backend 8082:8082 >/dev/null 2>&1 &

echo
echo "Tunnels up. Ctrl-C to stop."
wait
