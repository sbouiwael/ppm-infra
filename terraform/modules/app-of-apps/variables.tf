variable "namespace" {
  description = "Argo CD namespace"
  type        = string
  default     = "argocd"
}

variable "gitops_repo_url" {
  description = "URL of the ppm-gitops repository Argo CD will watch"
  type        = string
}

variable "gitops_target_revision" {
  description = "Branch / tag / SHA of the GitOps repo"
  type        = string
  default     = "main"
}

# Selects which env folder under apps/environments/ the root Application points to.
# "" => apps/environments (all envs). "local" => apps/environments/local only.
variable "env_filter" {
  description = "Single-env scope (\"local\", \"test\", \"staging\", \"prod\") or empty for all"
  type        = string
  default     = "local"
}
