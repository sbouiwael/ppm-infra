variable "namespace" {
  description = "Namespace for ingress-nginx (created by namespaces module)"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "ingress-nginx Helm chart version"
  type        = string
  default     = "4.11.3"
}

# NodePort by default because:
#   - Minikube has no cloud LoadBalancer
#   - kind/k3d also don't have one out of the box
#   - LoadBalancer would stay <pending> forever and confuse the demo
# Override to "LoadBalancer" the day a real cluster with a provisioner is used.
variable "service_type" {
  description = "Service type for the controller (NodePort | LoadBalancer | ClusterIP)"
  type        = string
  default     = "NodePort"
}

variable "http_node_port" {
  description = "NodePort for HTTP (only used when service_type=NodePort)"
  type        = number
  default     = 30080
}

variable "https_node_port" {
  description = "NodePort for HTTPS (only used when service_type=NodePort)"
  type        = number
  default     = 30443
}
