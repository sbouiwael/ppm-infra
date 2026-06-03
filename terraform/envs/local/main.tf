# ==============================================================
# envs/local — Minikube / kind / k3d composition
# Brings up: namespaces → ingress-nginx → Argo CD → MySQL → ppm Secret → App-of-Apps
# A single `terraform apply` should yield a working PPM stack.
# ==============================================================

module "namespaces" {
  source = "../../modules/namespaces"

  namespaces = merge(
    {
      argocd      = { "app.kubernetes.io/managed-by" = "terraform" }
      "ppm-local" = { environment = "local", "app.kubernetes.io/managed-by" = "argocd" }
    },
    var.install_ingress_nginx ? {
      "ingress-nginx" = { "app.kubernetes.io/managed-by" = "terraform" }
    } : {},
  )
}

module "ingress_nginx" {
  count  = var.install_ingress_nginx ? 1 : 0
  source = "../../modules/ingress-nginx"

  namespace     = "ingress-nginx"
  chart_version = var.ingress_nginx_chart_version
  service_type  = "NodePort"

  depends_on = [module.namespaces]
}

module "argocd" {
  source = "../../modules/argocd"

  namespace     = "argocd"
  chart_version = var.argocd_chart_version

  depends_on = [module.namespaces]
}

module "mysql_local" {
  count  = var.install_mysql_local ? 1 : 0
  source = "../../modules/mysql-local"

  namespace     = "ppm-local"
  release_name  = "ppm-mysql"
  chart_version = var.mysql_chart_version
  database      = "PPM"
  username      = "ppm_user"

  depends_on = [module.namespaces]
}

# Secret consumed by ppm-backend deployment in ppm-local namespace.
# DB_PASSWORD is wired to the local MySQL output so they stay in sync.
module "ppm_secrets_local" {
  source = "../../modules/ppm-secrets"

  namespace   = "ppm-local"
  secret_name = "ppm-backend-secrets-local"

  # If install_mysql_local=false, the user MUST set TF_VAR_external_db_password
  # via a tfvars file (gitignored). We never put a literal default here.
  db_password = var.install_mysql_local ? module.mysql_local[0].user_password : null

  depends_on = [module.namespaces]
}

# Final step: hand control over to Argo CD by applying a root Application
# scoped to apps/environments/local in the GitOps repo.
module "app_of_apps" {
  source = "../../modules/app-of-apps"

  namespace              = "argocd"
  gitops_repo_url        = var.gitops_repo_url
  gitops_target_revision = var.gitops_target_revision
  env_filter             = "local"

  depends_on = [
    module.argocd,
    module.ppm_secrets_local,
  ]
}
