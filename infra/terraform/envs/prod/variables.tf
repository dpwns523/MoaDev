variable "service_name" {
  description = "Primary service name for labels and release naming."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must be a non-empty string."
  }
}

variable "platform_topology" {
  description = "High-level platform shape consumed by the shared Terraform contract."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.platform_topology) != ""
    error_message = "platform_topology must be a non-empty string."
  }
}

variable "cluster_topology" {
  description = "Shared cluster topology settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "domains" {
  description = "Shared domain settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "images" {
  description = "Shared image settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "namespaces" {
  description = "Shared namespace settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "ingress" {
  description = "Ingress settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "scheduling" {
  description = "Scheduling settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "cicd" {
  description = "CI/CD settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "monitoring" {
  description = "Monitoring settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "storage" {
  description = "Storage settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "cost_automation" {
  description = "Cost automation settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "oci_cluster" {
  description = "OCI provider settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}

variable "aws_cluster" {
  description = "AWS provider settings forwarded to the platform contract module."
  type        = any
  nullable    = false
}
