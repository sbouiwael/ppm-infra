# Local in-cluster MySQL for the "local" environment.
# Cloud environments should NOT use this — they use a managed DB (RDS / CloudSQL / Azure DB)
# wired in via External Secrets Operator. This module is intentionally scoped to local dev.

resource "random_password" "root" {
  length      = 32
  special     = false
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
}

resource "random_password" "user" {
  length      = 32
  special     = false
  min_upper   = 4
  min_lower   = 4
  min_numeric = 4
}

locals {
  effective_user_password = coalesce(var.user_password, random_password.user.result)
}

resource "helm_release" "mysql" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = false

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = var.chart_version

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    yamlencode({
      architecture = "standalone"
      auth = {
        rootPassword   = random_password.root.result
        database       = var.database
        username       = var.username
        password       = local.effective_user_password
        createDatabase = true
      }
      primary = {
        persistence = {
          enabled      = true
          size         = var.storage_size
          storageClass = var.storage_class
        }
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
        service = {
          type = "ClusterIP"
          ports = {
            mysql = 3306
          }
        }
      }
      metrics = { enabled = false }
    })
  ]
}

output "host" {
  value = "${var.release_name}.${var.namespace}.svc.cluster.local"
}

output "port" {
  value = 3306
}

output "database" {
  value = var.database
}

output "username" {
  value = var.username
}

output "user_password" {
  value     = local.effective_user_password
  sensitive = true
}
