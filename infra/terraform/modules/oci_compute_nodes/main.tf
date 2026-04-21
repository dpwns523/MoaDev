locals {
  oci_worker_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.provider == "oci" && node_group.role == "worker"
  }

  node_group_plan = {
    for name, node_group in local.oci_worker_node_groups :
    name => {
      provider             = "oci"
      role                 = node_group.role
      desired_count        = node_group.desired_count
      min_count            = node_group.min_count
      max_count            = node_group.max_count
      scaling_strategy     = node_group.scaling_strategy
      worker_shape         = var.worker_shape
      worker_ocpus         = var.worker_ocpus
      worker_memory_gbs    = var.worker_memory_gbs
      boot_volume_gbs      = var.worker_boot_volume_gbs
      subnet_refs          = var.worker_subnet_refs
      workload_placement   = var.workload_placement
      worker_placement     = var.worker_placement
      storage_class        = var.storage_class
      labels               = var.labels
      resource_name_prefix = format("%s-%s", var.name_prefix, name)
    }
  }
}

check "oci_worker_groups_have_subnets" {
  assert {
    condition     = length(local.oci_worker_node_groups) == 0 || length(var.worker_subnet_refs) > 0
    error_message = "OCI worker node groups require at least one worker subnet reference."
  }
}

check "oci_volume_sizes_are_positive" {
  assert {
    condition     = var.worker_boot_volume_gbs > 0
    error_message = "OCI worker boot volume size must be positive."
  }
}
