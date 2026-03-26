variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "service_name" {
  description = "Primary service name for labels and release naming."
  type        = string
}

locals {
  labels = {
    environment = var.environment
    service     = var.service_name
  }
}

output "labels" {
  value = local.labels
}

output "release_name" {
  value = "${var.service_name}-${var.environment}"
}
