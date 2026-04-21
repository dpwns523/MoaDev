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

variable "shared_labels" {
  description = "Shared label and name-prefix settings for infrastructure modules."
  type = object({
    naming_prefix_pattern = string
    labels                = list(string)
  })
  nullable = false

  validation {
    condition = (
      trimspace(var.shared_labels.naming_prefix_pattern) != "" &&
      length(var.shared_labels.labels) > 0
    )
    error_message = "shared_labels must define a non-empty naming_prefix_pattern and at least one label key."
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
  description = "OCI provider settings forwarded to the platform contract module and OCI skeleton modules."
  type = object({
    region                 = string
    tenancy_ocid           = string
    compartment_ocid       = string
    network_mode           = optional(string, "reference")
    vcn_ocid               = optional(string)
    vcn_cidr               = optional(string)
    availability_domains   = optional(list(string), [])
    worker_subnet_ocids    = optional(list(string), [])
    worker_subnet_cidrs    = optional(list(string), [])
    worker_shape           = string
    worker_ocpus           = number
    worker_memory_gbs      = number
    worker_boot_volume_gbs = optional(number, 50)
    workload_placement     = string
    storage_class          = string
    worker_placement       = optional(string, "private-subnets")
    bastion_enabled        = optional(bool, false)
  })
  nullable = false

  validation {
    condition = (
      trimspace(var.oci_cluster.region) != "" &&
      trimspace(var.oci_cluster.tenancy_ocid) != "" &&
      trimspace(var.oci_cluster.compartment_ocid) != "" &&
      contains(["create", "reference"], var.oci_cluster.network_mode) &&
      (
        var.oci_cluster.network_mode == "create" ?
        (
          can(cidrhost(var.oci_cluster.vcn_cidr, 0)) &&
          length(var.oci_cluster.availability_domains) > 0 &&
          length(var.oci_cluster.worker_subnet_cidrs) > 0 &&
          alltrue([for cidr in var.oci_cluster.worker_subnet_cidrs : can(cidrhost(cidr, 0))])
        ) :
        (
          trimspace(try(var.oci_cluster.vcn_ocid, "")) != "" &&
          length(var.oci_cluster.worker_subnet_ocids) > 0 &&
          alltrue([for subnet_id in var.oci_cluster.worker_subnet_ocids : trimspace(subnet_id) != ""])
        )
      ) &&
      trimspace(var.oci_cluster.worker_shape) != "" &&
      var.oci_cluster.worker_ocpus > 0 &&
      var.oci_cluster.worker_memory_gbs > 0 &&
      var.oci_cluster.worker_boot_volume_gbs > 0 &&
      trimspace(var.oci_cluster.workload_placement) != "" &&
      trimspace(var.oci_cluster.storage_class) != "" &&
      contains(["private-subnets", "mixed"], var.oci_cluster.worker_placement)
    )
    error_message = "oci_cluster must define provider identifiers, a supported network_mode, valid create/reference network inputs, positive sizing values, storage, and a supported worker_placement value."
  }
}

variable "aws_cluster" {
  description = "AWS provider settings forwarded to the platform contract module and AWS skeleton modules."
  type = object({
    region                            = string
    account_id                        = string
    network_mode                      = optional(string, "reference")
    vpc_id                            = optional(string)
    vpc_cidr                          = optional(string)
    availability_zones                = optional(list(string), [])
    control_plane_subnet_ids          = optional(list(string), [])
    worker_subnet_ids                 = optional(list(string), [])
    public_load_balancer_subnet_ids   = optional(list(string), [])
    control_plane_subnet_cidrs        = optional(list(string), [])
    worker_subnet_cidrs               = optional(list(string), [])
    public_load_balancer_subnet_cidrs = optional(list(string), [])
    control_plane_instance_type       = string
    worker_instance_type              = string
    control_plane_root_volume_gbs     = optional(number, 50)
    worker_root_volume_gbs            = optional(number, 80)
    worker_spot_enabled               = bool
    storage_class                     = string
    control_plane_endpoint_access     = optional(string, "private")
    control_plane_placement           = optional(string, "private-subnets")
    worker_placement                  = optional(string, "private-subnets")
    bastion_enabled                   = optional(bool, false)
  })
  nullable = false

  validation {
    condition = (
      trimspace(var.aws_cluster.region) != "" &&
      trimspace(var.aws_cluster.account_id) != "" &&
      contains(["create", "reference"], var.aws_cluster.network_mode) &&
      (
        var.aws_cluster.network_mode == "create" ?
        (
          can(cidrhost(var.aws_cluster.vpc_cidr, 0)) &&
          length(var.aws_cluster.availability_zones) > 0 &&
          length(var.aws_cluster.control_plane_subnet_cidrs) > 0 &&
          alltrue([for cidr in var.aws_cluster.control_plane_subnet_cidrs : can(cidrhost(cidr, 0))]) &&
          length(var.aws_cluster.worker_subnet_cidrs) > 0 &&
          alltrue([for cidr in var.aws_cluster.worker_subnet_cidrs : can(cidrhost(cidr, 0))]) &&
          length(var.aws_cluster.public_load_balancer_subnet_cidrs) > 0 &&
          alltrue([for cidr in var.aws_cluster.public_load_balancer_subnet_cidrs : can(cidrhost(cidr, 0))])
        ) :
        (
          trimspace(try(var.aws_cluster.vpc_id, "")) != "" &&
          length(var.aws_cluster.control_plane_subnet_ids) > 0 &&
          alltrue([for subnet_id in var.aws_cluster.control_plane_subnet_ids : trimspace(subnet_id) != ""]) &&
          length(var.aws_cluster.worker_subnet_ids) > 0 &&
          alltrue([for subnet_id in var.aws_cluster.worker_subnet_ids : trimspace(subnet_id) != ""]) &&
          length(var.aws_cluster.public_load_balancer_subnet_ids) > 0 &&
          alltrue([for subnet_id in var.aws_cluster.public_load_balancer_subnet_ids : trimspace(subnet_id) != ""])
        )
      ) &&
      trimspace(var.aws_cluster.control_plane_instance_type) != "" &&
      trimspace(var.aws_cluster.worker_instance_type) != "" &&
      var.aws_cluster.control_plane_root_volume_gbs > 0 &&
      var.aws_cluster.worker_root_volume_gbs > 0 &&
      trimspace(var.aws_cluster.storage_class) != "" &&
      contains(["private", "public"], var.aws_cluster.control_plane_endpoint_access) &&
      contains(["private-subnets", "public-subnets", "mixed"], var.aws_cluster.control_plane_placement) &&
      contains(["private-subnets", "public-subnets", "mixed"], var.aws_cluster.worker_placement)
    )
    error_message = "aws_cluster must define provider identifiers, a supported network_mode, valid create/reference network inputs, positive volume sizes, instance types, storage, and supported placement/access values."
  }
}

variable "aws_dev_scheduler" {
  description = "Optional AWS dev capacity scheduler settings for the infrastructure skeleton."
  type = object({
    enabled        = bool
    target_scope   = string
    start_schedule = string
    stop_schedule  = string
  })
  default  = null
  nullable = true

  validation {
    condition = (
      var.aws_dev_scheduler == null ||
      contains(["workers_only", "include_control_plane", "disabled"], var.aws_dev_scheduler.target_scope)
    )
    error_message = "aws_dev_scheduler.target_scope must be workers_only, include_control_plane, or disabled."
  }
}
