variable "namespace" {
  description = "Namespace where MySQL is installed (must already exist)"
  type        = string
  default     = "ppm-local"
}

variable "release_name" {
  description = "Helm release name — also drives the in-cluster service DNS"
  type        = string
  default     = "ppm-mysql"
}

variable "chart_version" {
  description = "Bitnami MySQL Helm chart version"
  type        = string
  default     = "11.1.19"
}

variable "database" {
  description = "Database name to create"
  type        = string
  default     = "PPM"
}

variable "username" {
  description = "Non-root user (used by the application)"
  type        = string
  default     = "ppm_user"
}

# When null, a random password is generated and stored in tfstate only.
# Pass a value via TF_VAR_* or terraform.tfvars (gitignored) to pin one.
variable "user_password" {
  description = "Password for the application user. Leave null to autogenerate."
  type        = string
  default     = null
  sensitive   = true
}

variable "storage_size" {
  description = "PVC size for MySQL data"
  type        = string
  default     = "2Gi"
}

variable "storage_class" {
  description = "StorageClass (empty = cluster default)"
  type        = string
  default     = ""
}
