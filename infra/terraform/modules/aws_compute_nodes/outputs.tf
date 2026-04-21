output "node_group_plan" {
  description = "Planned AWS node group skeleton keyed by node group name."
  value       = local.node_group_plan
}

output "control_plane_node_group_names" {
  description = "AWS control-plane node group names."
  value       = sort(keys(local.aws_control_plane_node_groups))
}

output "worker_node_group_names" {
  description = "AWS worker node group names."
  value       = sort(keys(local.aws_worker_node_groups))
}

output "summary" {
  description = "Safe summary of the AWS compute node skeleton."
  value = {
    cluster_name                = var.cluster_topology.cluster_name
    control_plane_instance_type = var.control_plane_instance_type
    worker_instance_type        = var.worker_instance_type
    worker_spot_enabled         = var.worker_spot_enabled
    control_plane_groups        = sort(keys(local.aws_control_plane_node_groups))
    worker_groups               = sort(keys(local.aws_worker_node_groups))
    control_plane_subnet_refs   = var.control_plane_subnet_refs
    worker_subnet_refs          = var.worker_subnet_refs
    storage_class               = var.storage_class
  }
}
