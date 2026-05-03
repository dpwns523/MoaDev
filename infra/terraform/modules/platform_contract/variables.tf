variable "environment" {
  description = "Deployment environment selected by the environment root directory."
  type        = string

  validation {
    condition     = trimspace(var.environment) != "" && !contains(["aws", "oci"], lower(var.environment))
    error_message = "environment must be a non-empty stage name such as dev or prod, not a provider name."
  }
}

variable "service_name" {
  description = "Primary service name for labels and Terraform outputs."
  type        = string

  validation {
    condition     = trimspace(var.service_name) != ""
    error_message = "service_name must be a non-empty string."
  }
}

variable "platform_topology" {
  description = "High-level platform shape."
  type        = string

  validation {
    condition     = contains(["single-provider", "multicloud"], var.platform_topology)
    error_message = "platform_topology must be either single-provider or multicloud."
  }
}

variable "cluster_topology" {
  description = "Shared cluster topology contract across providers."
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

  validation {
    condition = (
      trimspace(var.cluster_topology.cluster_name) != "" &&
      trimspace(var.cluster_topology.kubernetes_version) != "" &&
      trimspace(var.cluster_topology.cni_plugin) != "" &&
      contains(["aws", "oci"], var.cluster_topology.control_plane_provider) &&
      can(cidrhost(var.cluster_topology.pod_cidr, 0)) &&
      can(cidrhost(var.cluster_topology.service_cidr, 0)) &&
      length(var.cluster_topology.node_groups) > 0 &&
      alltrue([
        for node_group in values(var.cluster_topology.node_groups) :
        contains(["aws", "oci"], node_group.provider) &&
        contains(["control-plane", "worker"], node_group.role) &&
        trimspace(node_group.scaling_strategy) != "" &&
        node_group.min_count >= 0 &&
        node_group.desired_count >= node_group.min_count &&
        node_group.max_count >= node_group.desired_count
      ])
    )
    error_message = "cluster_topology must define valid CIDRs, a supported control-plane provider, and node groups with supported provider/role values and non-decreasing counts."
  }
}

variable "domains" {
  description = "Shared DNS and hostname contract."
  type = object({
    base    = string
    web     = string
    api     = string
    argocd  = string
    grafana = string
  })

  validation {
    condition = alltrue([
      trimspace(var.domains.base) != "",
      trimspace(var.domains.web) != "",
      trimspace(var.domains.api) != "",
      trimspace(var.domains.argocd) != "",
      trimspace(var.domains.grafana) != "",
    ])
    error_message = "domains values must be non-empty."
  }
}

variable "images" {
  description = "Image registry and repository contract."
  type = object({
    registry                  = string
    web_repository            = string
    api_repository            = string
    agents_runtime_repository = string
    tag                       = string
  })

  validation {
    condition = alltrue([
      trimspace(var.images.registry) != "",
      trimspace(var.images.web_repository) != "",
      trimspace(var.images.api_repository) != "",
      trimspace(var.images.agents_runtime_repository) != "",
      trimspace(var.images.tag) != "",
    ])
    error_message = "images values must be non-empty."
  }
}

variable "namespaces" {
  description = "Namespace ownership contract."
  type = object({
    app        = string
    platform   = string
    monitoring = string
    cicd       = string
  })

  validation {
    condition = alltrue([
      trimspace(var.namespaces.app) != "",
      trimspace(var.namespaces.platform) != "",
      trimspace(var.namespaces.monitoring) != "",
      trimspace(var.namespaces.cicd) != "",
    ])
    error_message = "namespaces values must be non-empty."
  }
}

variable "ingress" {
  description = "Ingress, DNS, and load-balancer contract."
  type = object({
    class_name             = string
    controller_replicas    = number
    external_dns_zone      = string
    load_balancer_provider = string
    load_balancer_scheme   = string
  })

  validation {
    condition = (
      trimspace(var.ingress.class_name) != "" &&
      var.ingress.controller_replicas >= 1 &&
      trimspace(var.ingress.external_dns_zone) != "" &&
      contains(["aws", "oci"], var.ingress.load_balancer_provider) &&
      contains(["internet-facing", "internal", "public", "private"], var.ingress.load_balancer_scheme)
    )
    error_message = "ingress must declare a supported provider, a supported scheme, a non-empty class_name/external_dns_zone, and controller_replicas >= 1."
  }
}

variable "scheduling" {
  description = "Cluster scheduling defaults."
  type = object({
    default_node_group     = string
    profile                = string
    topology_spread_policy = string
  })

  validation {
    condition = alltrue([
      trimspace(var.scheduling.default_node_group) != "",
      trimspace(var.scheduling.profile) != "",
      trimspace(var.scheduling.topology_spread_policy) != "",
    ])
    error_message = "scheduling values must be non-empty."
  }
}

variable "cicd" {
  description = "CI/CD and GitOps settings."
  type = object({
    gitops_repository          = string
    gitops_revision            = string
    sync_wave                  = number
    ci_artifact_retention_days = number
  })

  validation {
    condition = (
      trimspace(var.cicd.gitops_repository) != "" &&
      trimspace(var.cicd.gitops_revision) != "" &&
      var.cicd.sync_wave >= 0 &&
      var.cicd.ci_artifact_retention_days >= 1
    )
    error_message = "cicd must define a repository, revision, non-negative sync_wave, and artifact retention >= 1 day."
  }
}

variable "monitoring" {
  description = "Monitoring defaults."
  type = object({
    prometheus_retention = string
    loki_retention       = string
    grafana_admin_group  = string
    alert_route_email    = string
  })

  validation {
    condition = (
      trimspace(var.monitoring.prometheus_retention) != "" &&
      trimspace(var.monitoring.loki_retention) != "" &&
      trimspace(var.monitoring.grafana_admin_group) != "" &&
      can(regex(".+@.+", var.monitoring.alert_route_email))
    )
    error_message = "monitoring must define non-empty retention/admin values and an email-like alert_route_email."
  }
}

variable "storage" {
  description = "Shared storage and backup contract."
  type = object({
    artifact_bucket   = string
    backup_bucket     = string
    snapshot_schedule = string
  })

  validation {
    condition = alltrue([
      trimspace(var.storage.artifact_bucket) != "",
      trimspace(var.storage.backup_bucket) != "",
      trimspace(var.storage.snapshot_schedule) != "",
    ])
    error_message = "storage values must be non-empty."
  }
}

variable "cost_automation" {
  description = "Cost automation defaults."
  type = object({
    cost_center              = string
    monthly_budget_usd       = number
    idle_scale_down_enabled  = bool
    idle_scale_down_schedule = string
    report_schedule          = string
  })

  validation {
    condition = (
      trimspace(var.cost_automation.cost_center) != "" &&
      var.cost_automation.monthly_budget_usd >= 0 &&
      trimspace(var.cost_automation.idle_scale_down_schedule) != "" &&
      trimspace(var.cost_automation.report_schedule) != ""
    )
    error_message = "cost_automation must define a cost center, a non-negative budget, and non-empty schedules."
  }
}

variable "oci_cluster" {
  description = "Provider-specific OCI cluster contract."
  type = object({
    region               = string
    tenancy_ocid         = string
    compartment_ocid     = string
    network_mode         = optional(string, "reference")
    vcn_ocid             = optional(string)
    vcn_cidr             = optional(string)
    availability_domains = optional(list(string), [])
    existing_worker_subnet_bindings = optional(list(object({
      subnet_id           = string
      availability_domain = string
    })), [])
    worker_subnet_cidrs       = optional(list(string), [])
    worker_shape              = string
    worker_ocpus              = number
    worker_memory_gbs         = number
    worker_boot_volume_gbs    = optional(number, 50)
    workload_placement_intent = optional(string, "availability-domain-spread")
    storage_class             = string
    worker_placement_intent   = optional(string, "private-subnets")
    bastion_enabled           = optional(bool, false)
    nat_gateway_enabled       = optional(bool, true)
    image_ocid                = optional(string)
    ssh_authorized_keys       = optional(string)
    bootstrap_template_path   = optional(string)
    security_profile          = optional(string, "kubespray-default")
    ssh_access_mode           = optional(string, "cidr_allowlist")
    admin_ingress_cidrs       = optional(list(string), [])
    cluster_internal_cidrs    = optional(list(string), [])
  })

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
          length(var.oci_cluster.existing_worker_subnet_bindings) > 0 &&
          alltrue([
            for binding in var.oci_cluster.existing_worker_subnet_bindings :
            trimspace(binding.subnet_id) != "" && trimspace(binding.availability_domain) != ""
          ])
        )
      ) &&
      trimspace(var.oci_cluster.worker_shape) != "" &&
      var.oci_cluster.worker_ocpus > 0 &&
      var.oci_cluster.worker_memory_gbs > 0 &&
      var.oci_cluster.worker_boot_volume_gbs > 0 &&
      trimspace(var.oci_cluster.workload_placement_intent) != "" &&
      trimspace(var.oci_cluster.storage_class) != "" &&
      contains(["availability-domain-spread", "manual"], var.oci_cluster.workload_placement_intent) &&
      contains(["private-subnets", "mixed"], var.oci_cluster.worker_placement_intent) &&
      contains(["kubespray-default"], var.oci_cluster.security_profile) &&
      contains(["none", "cidr_allowlist"], var.oci_cluster.ssh_access_mode)
    )
    error_message = "oci_cluster must define non-empty provider identifiers, a supported network_mode, valid create/reference network inputs, positive sizing values, storage, and supported intent/access values."
  }
}

variable "aws_cluster" {
  description = "Provider-specific AWS cluster contract."
  type = object({
    region                               = string
    account_id                           = string
    network_mode                         = optional(string, "reference")
    vpc_id                               = optional(string)
    vpc_cidr                             = optional(string)
    availability_zones                   = optional(list(string), [])
    control_plane_subnet_ids             = optional(list(string), [])
    worker_subnet_ids                    = optional(list(string), [])
    public_load_balancer_subnet_ids      = optional(list(string), [])
    control_plane_subnet_cidrs           = optional(list(string), [])
    worker_subnet_cidrs                  = optional(list(string), [])
    public_load_balancer_subnet_cidrs    = optional(list(string), [])
    control_plane_instance_type          = string
    worker_instance_type                 = string
    control_plane_root_volume_gbs        = optional(number, 50)
    worker_root_volume_gbs               = optional(number, 80)
    worker_spot_enabled                  = bool
    storage_class                        = string
    control_plane_endpoint_access_intent = optional(string, "private_only")
    control_plane_placement_intent       = optional(string, "private-subnets")
    worker_placement_intent              = optional(string, "private-subnets")
    bastion_enabled                      = optional(bool, false)
    nat_gateway_enabled                  = optional(bool, true)
    nat_gateway_mode                     = optional(string, "single")
    ami_id                               = optional(string)
    ssh_key_name                         = optional(string)
    instance_profile_name                = optional(string)
    bootstrap_template_path              = optional(string)
    security_profile                     = optional(string, "kubespray-default")
    ssh_access_mode                      = optional(string, "cidr_allowlist")
    admin_ingress_cidrs                  = optional(list(string), [])
    kube_api_access_mode                 = optional(string, "private_only")
    kube_api_ingress_cidrs               = optional(list(string), [])
    cluster_internal_cidrs               = optional(list(string), [])
  })

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
      contains(["single"], var.aws_cluster.nat_gateway_mode) &&
      contains(["private_only", "public_allowlist"], var.aws_cluster.control_plane_endpoint_access_intent) &&
      contains(["private-subnets", "public-subnets", "mixed"], var.aws_cluster.control_plane_placement_intent) &&
      contains(["private-subnets", "public-subnets", "mixed"], var.aws_cluster.worker_placement_intent) &&
      contains(["kubespray-default"], var.aws_cluster.security_profile) &&
      contains(["none", "cidr_allowlist"], var.aws_cluster.ssh_access_mode) &&
      contains(["private_only", "public_allowlist"], var.aws_cluster.kube_api_access_mode)
    )
    error_message = "aws_cluster must define non-empty provider identifiers, a supported network_mode, valid create/reference network inputs, positive volume sizes, instance types, storage, and supported NAT/intent/access values."
  }
}
