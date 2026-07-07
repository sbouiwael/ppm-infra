terraform {
  required_version = ">= 1.5.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      # Capped below 3.0.0: the v3 provider replaced the nested `kubernetes {}`
      # block (used in providers.tf) with a `kubernetes = {}` attribute, which is
      # a breaking syntax change. Stay on the 2.x line that this config targets.
      version = ">= 2.13.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
}
