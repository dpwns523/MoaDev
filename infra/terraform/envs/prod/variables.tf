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
    condition     = contains(["single-provider", "multicloud"], var.platform_topology)
    error_message = "platform_topology must be either single-provider or multicloud."
  }
}

variable "cluster_topology" {
  description = "Shared cluster topology settings forwarded to the platform contract module."
  type = object({
    cluster_name           = string
    kubernetes_version     = string
    control_plane_provider = string
    cni_plugin             = string
    pod_cidr               = string
    service_cidr           = string
    node_groups = map(object({
      provider         = string
      role             = string
      desired_count    = number
      min_count        = number
      max_count        = number
      scaling_strategy = string
    }))
  })
  nullable = false
}

variable "domains" {
  description = "Shared domain settings forwarded to the platform contract module."
  type = object({
    base    = string
    web     = string
    api     = string
    argocd  = string
    grafana = string
  })
  nullable = false
}

variable "images" {
  description = "Shared image settings forwarded to the platform contract module."
  type = object({
    registry                  = string
    web_repository            = string
    api_repository            = string
    agents_runtime_repository = string
    tag                       = string
  })
  nullable = false
}

variable "namespaces" {
  description = "Shared namespace settings forwarded to the platform contract module."
  type = object({
    app        = string
    platform   = string
    monitoring = string
    cicd       = string
  })
  nullable = false
}

variable "ingress" {
  description = "Ingress settings forwarded to the platform contract module."
  type = object({
    class_name             = string
    controller_replicas    = number
    external_dns_zone      = string
    load_balancer_provider = string
    load_balancer_scheme   = string
  })
  nullable = false
}

variable "scheduling" {
  description = "Scheduling settings forwarded to the platform contract module."
  type = object({
    default_node_group     = string
    profile                = string
    topology_spread_policy = string
  })
  nullable = false
}

variable "cicd" {
  description = "CI/CD settings forwarded to the platform contract module."
  type = object({
    gitops_repository          = string
    gitops_revision            = string
    sync_wave                  = number
    ci_artifact_retention_days = number
  })
  nullable = false
}

variable "monitoring" {
  description = "Monitoring settings forwarded to the platform contract module."
  type = object({
    prometheus_retention = string
    loki_retention       = string
    grafana_admin_group  = string
    alert_route_email    = string
  })
  nullable = false
}

variable "storage" {
  description = "Storage settings forwarded to the platform contract module."
  type = object({
    artifact_bucket   = string
    backup_bucket     = string
    snapshot_schedule = string
  })
  nullable = false
}

variable "cost_automation" {
  description = "Cost automation settings forwarded to the platform contract module."
  type = object({
    cost_center              = string
    monthly_budget_usd       = number
    idle_scale_down_enabled  = bool
    idle_scale_down_schedule = string
    report_schedule          = string
  })
  nullable = false
}

variable "oci_cluster" {
  description = "OCI provider settings forwarded to the platform contract module."
  type = object({
    region              = string
    tenancy_ocid        = string
    compartment_ocid    = string
    vcn_ocid            = string
    worker_subnet_ocids = list(string)
    worker_shape        = string
    worker_ocpus        = number
    worker_memory_gbs   = number
    workload_placement  = string
    storage_class       = string
    worker_placement    = optional(string, "private-subnets")
    bastion_enabled     = optional(bool, false)
  })
  nullable = false
}

variable "aws_cluster" {
  description = "AWS provider settings forwarded to the platform contract module."
  type = object({
    region                          = string
    account_id                      = string
    vpc_id                          = string
    control_plane_subnet_ids        = list(string)
    worker_subnet_ids               = list(string)
    public_load_balancer_subnet_ids = list(string)
    control_plane_instance_type     = string
    worker_instance_type            = string
    worker_spot_enabled             = bool
    storage_class                   = string
    control_plane_endpoint_access   = optional(string, "private")
    control_plane_placement         = optional(string, "private-subnets")
    worker_placement                = optional(string, "private-subnets")
    bastion_enabled                 = optional(bool, false)
  })
  nullable = false
}
