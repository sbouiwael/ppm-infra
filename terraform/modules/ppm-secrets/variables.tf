variable "namespace" {
  description = "Target namespace (must already exist)"
  type        = string
}

variable "secret_name" {
  description = "Name of the Kubernetes Secret the backend Helm chart references"
  type        = string
  default     = "ppm-backend-secrets-local"
}

variable "db_password" {
  description = "Database password — required, must match the MySQL release"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret. Leave null to autogenerate a 64-byte hex string."
  type        = string
  default     = null
  sensitive   = true
}

variable "extra_data" {
  description = "Additional key/value pairs to put in the Secret"
  type        = map(string)
  default     = {}
  sensitive   = true
}
