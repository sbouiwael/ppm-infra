# Local-friendly Argo CD install:
#   - Single replica (HA disabled)
#   - server.service.type=ClusterIP   → no cloud LoadBalancer
#   - insecure=true                   → Argo CD serves plain HTTP behind port-forward
#   - dex disabled                    → no OIDC by default; flip later via values_overrides
locals {
  baseline_values = {
    global = {
      domain = "argocd.local"
    }
    configs = {
      params = {
        "server.insecure" = "true"
      }
    }
    server = {
      service = {
        type = "ClusterIP"
      }
      ingress = {
        enabled = false
      }
    }
    dex = {
      enabled = false
    }
    notifications = {
      enabled = false
    }
    redis-ha = {
      enabled = false
    }
    controller = {
      replicas = 1
    }
    repoServer = {
      replicas = 1
    }
    applicationSet = {
      replicas = 1
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  create_namespace = false # namespace module owns it

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  # Wait for CRDs and Deployments before returning — required so the
  # downstream app-of-apps module can apply argoproj.io/v1alpha1 manifests.
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    yamlencode(local.baseline_values),
    yamlencode(var.values_overrides),
  ]
}

output "namespace" {
  value = var.namespace
}

output "release_name" {
  value = helm_release.argocd.name
}
