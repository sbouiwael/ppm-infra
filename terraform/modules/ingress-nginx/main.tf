locals {
  baseline_values = {
    controller = {
      replicaCount = 1
      service = {
        type = var.service_type
        nodePorts = var.service_type == "NodePort" ? {
          http  = var.http_node_port
          https = var.https_node_port
        } : null
      }
      ingressClassResource = {
        name    = "nginx"
        default = true
      }
      admissionWebhooks = {
        # Admission webhook needs cert-manager OR a self-cert job.
        # The chart ships a built-in patch job — keep it on, just shrink resources.
        enabled = true
      }
      # Sensible local resource footprint
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "256Mi" }
      }
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = var.namespace
  create_namespace = false

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [yamlencode(local.baseline_values)]
}

output "namespace" {
  value = var.namespace
}

output "service_type" {
  value = var.service_type
}
