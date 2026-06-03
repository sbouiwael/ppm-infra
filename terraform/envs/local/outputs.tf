output "argocd_namespace" {
  value = module.argocd.namespace
}

output "mysql_host" {
  value       = var.install_mysql_local ? module.mysql_local[0].host : "(external)"
  description = "In-cluster MySQL DNS host (or '(external)' if disabled)"
}

output "mysql_credentials" {
  value = var.install_mysql_local ? {
    host     = module.mysql_local[0].host
    port     = module.mysql_local[0].port
    database = module.mysql_local[0].database
    username = module.mysql_local[0].username
  } : null
  description = "Non-secret MySQL coordinates"
}

output "next_steps" {
  value = <<-EOT

    Stack bootstrapped. Next steps:

      1. Watch sync status:
           kubectl get applications -n argocd -w

      2. Get Argo CD admin password (auto-generated):
           kubectl -n argocd get secret argocd-initial-admin-secret \
             -o jsonpath='{.data.password}' | base64 -d ; echo

      3. Open Argo CD UI:
           kubectl -n argocd port-forward svc/argocd-server 8080:80
           # then visit http://localhost:8080  (user: admin)

      4. Reach the app:
           kubectl -n ppm-local port-forward svc/ppm-frontend 4200:80
           kubectl -n ppm-local port-forward svc/ppm-backend  8082:8082
           # frontend at http://localhost:4200
           # backend  at http://localhost:8082/actuator/health
  EOT
}
