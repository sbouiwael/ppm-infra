#!/usr/bin/env bash
# Stop and optionally delete the Minikube profile used for PPM.
set -euo pipefail

PROFILE="${MINIKUBE_PROFILE:-ppm}"
MODE="${1:-stop}"  # stop | delete

case "$MODE" in
  stop)
    minikube stop -p "$PROFILE"
    ;;
  delete)
    minikube delete -p "$PROFILE"
    ;;
  *)
    echo "Usage: $0 [stop|delete]" >&2
    exit 2
    ;;
esac
