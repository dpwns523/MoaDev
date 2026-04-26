output "node_group_plan" {
  description = "Planned AWS node group skeleton keyed by node group name."
  value       = local.node_group_plan
}

output "control_plane_instance_refs" {
  description = "Provider-backed AWS control-plane instance references keyed by instance name."
  value = {
    for name, instance in aws_instance.control_plane :
    name => {
      id                = instance.id
      availability_zone = instance.availability_zone
      private_ip        = instance.private_ip
      subnet_id         = instance.subnet_id
    }
  }
}

output "worker_instance_refs" {
  description = "Provider-backed AWS worker instance references keyed by instance name."
  value = {
    for name, instance in aws_instance.worker :
    name => {
      id                = instance.id
      availability_zone = instance.availability_zone
      private_ip        = instance.private_ip
      subnet_id         = instance.subnet_id
    }
  }
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
  description = "Safe summary of the AWS compute node foundation."
  value = {
    cluster_name                = var.cluster_topology.cluster_name
    control_plane_instance_type = var.control_plane_instance_type
    worker_instance_type        = var.worker_instance_type
    worker_spot_enabled         = var.worker_spot_enabled
    control_plane_groups        = sort(keys(local.aws_control_plane_node_groups))
    worker_groups               = sort(keys(local.aws_worker_node_groups))
    control_plane_instances     = sort(keys(local.control_plane_instance_plan))
    worker_instances            = sort(keys(local.worker_instance_plan))
    control_plane_subnet_refs   = var.control_plane_subnet_refs
    worker_subnet_refs          = var.worker_subnet_refs
    storage_class               = var.storage_class
    resource_mode               = local.aws_instance_resources_enabled ? "provider-backed-vm" : "contract-only-until-ami-is-set"
  }
}
