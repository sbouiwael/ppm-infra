# Provider configuration — talks to the cluster pointed to by your current kubeconfig.
# Defaults assume Minikube. To target any other cluster just set:
#   TF_VAR_kube_context=<context-name>
#   TF_VAR_kube_config_path=<path>
#
# NO cloud SDK is wired in. This is intentional — the design requirement is
# "portable" + "no cloud Terraform". A future ppm-infra/terraform/envs/<cloud>
# folder may add aws/azurerm/google providers when a target is chosen.

provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kube_config_path
    config_context = var.kube_context
  }
}

provider "kubectl" {
  config_path      = var.kube_config_path
  config_context   = var.kube_context
  load_config_file = true
}
