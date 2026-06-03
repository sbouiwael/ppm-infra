# ==============================================================
# ppm-infra — convenience targets
# Usage:  make help
# ==============================================================

SHELL := /usr/bin/env bash
ENV_DIR := terraform/envs/local

.PHONY: help minikube-up minikube-stop minikube-delete \
        init plan apply destroy bootstrap \
        sync-status argocd-password port-forward \
        fmt validate

help:
	@echo ""
	@echo "Cluster lifecycle"
	@echo "  minikube-up      Start the Minikube profile 'ppm'"
	@echo "  minikube-stop    Stop the profile"
	@echo "  minikube-delete  Delete the profile (data lost)"
	@echo ""
	@echo "Terraform"
	@echo "  init             terraform init"
	@echo "  plan             terraform plan"
	@echo "  apply / bootstrap  terraform apply -auto-approve"
	@echo "  destroy          terraform destroy"
	@echo "  fmt              terraform fmt -recursive"
	@echo "  validate         terraform validate"
	@echo ""
	@echo "Cluster ops"
	@echo "  sync-status      Watch Argo CD Applications"
	@echo "  argocd-password  Print Argo CD initial admin password"
	@echo "  port-forward     Open Argo CD UI + frontend + backend tunnels"
	@echo ""

# -- Cluster lifecycle --
minikube-up:
	bash scripts/minikube-up.sh

minikube-stop:
	bash scripts/minikube-down.sh stop

minikube-delete:
	bash scripts/minikube-down.sh delete

# -- Terraform --
init:
	cd $(ENV_DIR) && terraform init -upgrade

plan:
	cd $(ENV_DIR) && terraform plan

apply bootstrap:
	bash scripts/bootstrap.sh

destroy:
	cd $(ENV_DIR) && terraform destroy

fmt:
	terraform fmt -recursive terraform/

validate:
	cd $(ENV_DIR) && terraform init -backend=false -upgrade >/dev/null && terraform validate

# -- Cluster ops --
sync-status:
	kubectl get applications -n argocd -w

argocd-password:
	bash scripts/argocd-password.sh

port-forward:
	bash scripts/port-forward.sh
