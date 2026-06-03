variable "namespace" {
  description = "Namespace where Argo CD is installed"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version (https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)"
  type        = string
  default     = "7.7.10"
}

variable "values_overrides" {
  description = "Extra Helm values merged on top of the local-friendly baseline"
  type        = map(any)
  default     = {}
}
