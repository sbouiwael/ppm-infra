variable "kube_config_path" {
  description = "Path to kubeconfig (~/.kube/config by default)"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubeconfig context to use (e.g. minikube, kind-ppm, docker-desktop)"
  type        = string
  default     = "minikube"
}

variable "gitops_repo_url" {
  description = "GitOps repo URL Argo CD will watch"
  type        = string
  default     = "https://github.com/sbouiwael/ppm-gitops.git"
}

variable "gitops_target_revision" {
  description = "Branch/tag/SHA of the GitOps repo"
  type        = string
  default     = "main"
}

# Image tags for the local env can be promoted manually by editing
# ppm-gitops/charts/ppm-{backend,frontend}/values-local.yaml.
# The promote-test CI job does NOT touch values-local.yaml (only values-test.yaml),
# so promotions to local are explicit.

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
  default     = "7.7.10"
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.11.3"
}

variable "mysql_chart_version" {
  description = "Bitnami MySQL Helm chart version"
  type        = string
  default     = "11.1.19"
}

variable "install_ingress_nginx" {
  description = "Install ingress-nginx as part of bootstrap (set false if cluster already has one)"
  type        = bool
  default     = true
}

variable "install_mysql_local" {
  description = "Install in-cluster MySQL for the local env (false to point at an external DB)"
  type        = bool
  default     = true
}
