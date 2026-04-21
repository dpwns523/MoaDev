locals {
  aws_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.provider == "aws"
  }

  aws_control_plane_node_groups = {
    for name, node_group in local.aws_node_groups :
    name => node_group if node_group.role == "control-plane"
  }

  aws_worker_node_groups = {
    for name, node_group in local.aws_node_groups :
    name => node_group if node_group.role == "worker"
  }

  control_plane_plan = {
    for name, node_group in local.aws_control_plane_node_groups :
    name => {
      provider                  = "aws"
      role                      = node_group.role
      desired_count             = node_group.desired_count
      min_count                 = node_group.min_count
      max_count                 = node_group.max_count
      scaling_strategy          = node_group.scaling_strategy
      instance_type             = var.control_plane_instance_type
      root_volume_gbs           = var.control_plane_root_volume_gbs
      subnet_refs               = var.control_plane_subnet_refs
      endpoint_access           = var.control_plane_endpoint_access
      placement                 = var.control_plane_placement
      storage_class             = var.storage_class
      supports_future_scale_out = node_group.max_count > node_group.desired_count
      labels                    = var.labels
      resource_name_prefix      = format("%s-%s", var.name_prefix, name)
    }
  }

  worker_plan = {
    for name, node_group in local.aws_worker_node_groups :
    name => {
      provider             = "aws"
      role                 = node_group.role
      desired_count        = node_group.desired_count
      min_count            = node_group.min_count
      max_count            = node_group.max_count
      scaling_strategy     = node_group.scaling_strategy
      instance_type        = var.worker_instance_type
      root_volume_gbs      = var.worker_root_volume_gbs
      subnet_refs          = var.worker_subnet_refs
      placement            = var.worker_placement
      storage_class        = var.storage_class
      spot_enabled         = var.worker_spot_enabled
      labels               = var.labels
      resource_name_prefix = format("%s-%s", var.name_prefix, name)
    }
  }

  node_group_plan = merge(local.control_plane_plan, local.worker_plan)
}

check "aws_control_plane_groups_have_subnets" {
  assert {
    condition     = length(local.aws_control_plane_node_groups) == 0 || length(var.control_plane_subnet_refs) > 0
    error_message = "AWS control-plane node groups require at least one control-plane subnet reference."
  }
}

check "aws_worker_groups_have_subnets" {
  assert {
    condition     = length(local.aws_worker_node_groups) == 0 || length(var.worker_subnet_refs) > 0
    error_message = "AWS worker node groups require at least one worker subnet reference."
  }
}

check "aws_volume_sizes_are_positive" {
  assert {
    condition     = var.control_plane_root_volume_gbs > 0 && var.worker_root_volume_gbs > 0
    error_message = "AWS root volume sizes must be positive."
  }
}
