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

# Bitnami moved its free/legacy container images out of docker.io/bitnami/* in
# 2025 (the versioned tags this chart references were deleted from docker.io/bitnami
# and republished under docker.io/bitnamilegacy/*). The chart default
# (image.repository = bitnami/mysql) therefore yields ImagePullBackOff. Point at
# the legacy repo so the pinned tag for chart_version stays pullable. Override if
# you mirror the image elsewhere.
variable "image_repository" {
  description = "Image repository for MySQL (registry stays docker.io). Defaults to the Bitnami legacy repo so the chart's pinned tag remains pullable."
  type        = string
  default     = "bitnamilegacy/mysql"
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
