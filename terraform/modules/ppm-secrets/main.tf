# Creates the Kubernetes Secret expected by ppm-backend's deployment.yaml.
# Real cloud deployments should drive this via External Secrets Operator instead —
# this module is intentionally minimal for local Minikube bootstrap.

resource "random_id" "jwt" {
  byte_length = 64
}

locals {
  effective_jwt = coalesce(var.jwt_secret, random_id.jwt.hex)
}

resource "kubernetes_secret_v1" "backend" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "ppm"
    }
  }

  type = "Opaque"

  data = merge(
    {
      DB_PASSWORD = var.db_password
      JWT_SECRET  = local.effective_jwt
    },
    var.extra_data,
  )
}

output "secret_name" {
  value = kubernetes_secret_v1.backend.metadata[0].name
}

output "jwt_secret" {
  value     = local.effective_jwt
  sensitive = true
}
