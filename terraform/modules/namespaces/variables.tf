variable "namespaces" {
  description = "Map of namespace name => labels"
  type        = map(map(string))
  default = {
    argocd        = { "app.kubernetes.io/managed-by" = "terraform" }
    "ppm-local"   = { environment = "local", "app.kubernetes.io/managed-by" = "argocd" }
    "ingress-nginx" = { "app.kubernetes.io/managed-by" = "terraform" }
  }
}
