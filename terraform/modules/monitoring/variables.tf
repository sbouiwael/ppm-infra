variable "namespace" {
  description = "Namespace where the observability stack is installed"
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "kube-prometheus-stack Helm chart version (Prometheus + Grafana + Alertmanager + exporters)"
  type        = string
  default     = "86.2.2"
}

variable "loki_stack_version" {
  description = "loki-stack Helm chart version (Loki single-binary + Promtail)"
  type        = string
  default     = "2.10.3"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (user: admin). Local demo default; override in cloud."
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "prometheus_retention" {
  description = "How long Prometheus keeps metrics. Short by default to stay light on Minikube."
  type        = string
  default     = "12h"
}

variable "prometheus_storage_size" {
  description = "PVC size for Prometheus TSDB"
  type        = string
  default     = "5Gi"
}

variable "storage_class" {
  description = "StorageClass for Prometheus PVC (empty = cluster default)"
  type        = string
  default     = ""
}