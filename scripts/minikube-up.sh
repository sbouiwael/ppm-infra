#!/usr/bin/env bash
# Boot a Minikube cluster sized for the PPM stack.
# Idempotent — safe to re-run; will skip if cluster already exists.
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-ppm}"
CPUS="${MINIKUBE_CPUS:-4}"
MEMORY="${MINIKUBE_MEMORY:-6144}"
DISK="${MINIKUBE_DISK:-20g}"
DRIVER="${MINIKUBE_DRIVER:-docker}"
K8S_VERSION="${MINIKUBE_K8S:-v1.30.5}"

if ! command -v minikube >/dev/null 2>&1; then
  echo "ERROR: minikube not installed. https://minikube.sigs.k8s.io/docs/start/" >&2
  exit 1
fi

if minikube status -p "$PROFILE" >/dev/null 2>&1; then
  echo "Profile '$PROFILE' already running. Skipping start."
else
  echo "Starting Minikube profile '$PROFILE'..."
  minikube start \
    --profile "$PROFILE" \
    --driver "$DRIVER" \
    --kubernetes-version "$K8S_VERSION" \
    --cpus "$CPUS" \
    --memory "$MEMORY" \
    --disk-size "$DISK"
fi

echo "Setting kubectl context to '$PROFILE'..."
kubectl config use-context "$PROFILE"

echo
echo "Cluster ready. Next:"
echo "  cd terraform/envs/local && terraform init && terraform apply"
echo
echo "Or use:  make bootstrap"
