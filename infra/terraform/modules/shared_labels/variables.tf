variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = trimspace(var.environment) != ""
    error_message = "environment must be a non-empty string."
  }
}

variable "service_name" {
  description = "Primary service name used in generated labels and name prefixes."
  type        = string

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must be a non-empty string."
  }
}

variable "naming_prefix_pattern" {
  description = "Pattern for naming Terraform-managed resources. Supports {environment} and {service} placeholders."
  type        = string

  validation {
    condition     = trimspace(var.naming_prefix_pattern) != ""
    error_message = "naming_prefix_pattern must be a non-empty string."
  }
}

variable "labels" {
  description = "Ordered list of label keys to materialize into the shared label map."
  type        = list(string)

  validation {
    condition     = length(var.labels) > 0
    error_message = "labels must contain at least one label key."
  }
}

variable "track" {
  description = "Track label value shared across infrastructure resources."
  type        = string
  default     = "infra"
}

variable "managed_by" {
  description = "Managed-by label value shared across infrastructure resources."
  type        = string
  default     = "terraform"
}

variable "cost_center" {
  description = "Cost center label value shared across infrastructure resources."
  type        = string

  validation {
    condition     = trimspace(var.cost_center) != ""
    error_message = "cost_center must be a non-empty string."
  }
}
