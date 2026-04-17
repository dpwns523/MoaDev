locals {
  providers_in_use = sort(distinct([
    for node_group in values(var.cluster_topology.node_groups) :
    node_group.provider
  ]))

  control_plane_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.role == "control-plane"
  }

  worker_node_groups = {
    for name, node_group in var.cluster_topology.node_groups :
    name => node_group if node_group.role == "worker"
  }
}

check "control_plane_provider_has_control_plane_node_group" {
  assert {
    condition = length([
      for name, node_group in var.cluster_topology.node_groups :
      name if node_group.provider == var.cluster_topology.control_plane_provider && node_group.role == "control-plane"
    ]) > 0
    error_message = "cluster_topology.control_plane_provider must match at least one control-plane node group."
  }
}

check "platform_topology_matches_node_group_providers" {
  assert {
    condition = (
      (var.platform_topology == "multicloud" && length(local.providers_in_use) >= 2) ||
      (var.platform_topology == "single-provider" && length(local.providers_in_use) == 1)
    )
    error_message = "platform_topology must match the number of providers represented by cluster_topology.node_groups."
  }
}

check "default_node_group_exists_and_is_worker" {
  assert {
    condition = (
      contains(keys(var.cluster_topology.node_groups), var.scheduling.default_node_group) &&
      var.cluster_topology.node_groups[var.scheduling.default_node_group].role == "worker"
    )
    error_message = "scheduling.default_node_group must exist in cluster_topology.node_groups and reference a worker node group."
  }
}

check "load_balancer_provider_is_declared" {
  assert {
    condition     = contains(local.providers_in_use, var.ingress.load_balancer_provider)
    error_message = "ingress.load_balancer_provider must match a provider that appears in cluster_topology.node_groups."
  }
}
