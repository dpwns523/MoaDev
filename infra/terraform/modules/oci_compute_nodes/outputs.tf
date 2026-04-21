output "node_group_plan" {
  description = "Planned OCI worker node skeleton keyed by node group name."
  value       = local.node_group_plan
}

output "worker_node_group_names" {
  description = "OCI worker node group names."
  value       = sort(keys(local.oci_worker_node_groups))
}

output "summary" {
  description = "Safe summary of the OCI compute node skeleton."
  value = {
    cluster_name       = var.cluster_topology.cluster_name
    worker_shape       = var.worker_shape
    worker_ocpus       = var.worker_ocpus
    worker_memory_gbs  = var.worker_memory_gbs
    worker_groups      = sort(keys(local.oci_worker_node_groups))
    worker_subnet_refs = var.worker_subnet_refs
    workload_placement = var.workload_placement
    worker_placement   = var.worker_placement
    storage_class      = var.storage_class
  }
}
