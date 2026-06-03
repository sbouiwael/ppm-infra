# Applies a root Argo CD Application that itself points at apps/environments/<env_filter>
# in the GitOps repo. Argo CD then materializes every child Application found there.
#
# This is the same App-of-Apps pattern as apps/argocd/app-of-apps.yaml in ppm-gitops,
# but expressed via Terraform so the whole bootstrap is a single `terraform apply`.

locals {
  path = var.env_filter == "" ? "apps/environments" : "apps/environments/${var.env_filter}"
}

resource "kubectl_manifest" "app_of_apps" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "ppm-apps-${var.env_filter == "" ? "all" : var.env_filter}"
      namespace = var.namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_target_revision
        path           = local.path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
      }
    }
  })

  # Argo CD CRDs must already be installed (helm_release.argocd done).
  wait_for_rollout = false
}
