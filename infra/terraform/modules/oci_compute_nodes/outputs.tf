output "node_group_plan" {
  description = "Planned OCI worker node skeleton keyed by node group name."
  value       = local.node_group_plan
}

output "worker_instance_refs" {
  description = "Provider-backed OCI worker instance references keyed by instance name."
  value = {
    for name, instance in oci_core_instance.worker :
    name => {
      id                  = instance.id
      availability_domain = instance.availability_domain
      private_ip          = instance.private_ip
      subnet_id           = instance.create_vnic_details[0].subnet_id
    }
  }
}

output "worker_node_group_names" {
  description = "OCI worker node group names."
  value       = sort(keys(local.oci_worker_node_groups))
}

output "summary" {
  description = "Safe summary of the OCI compute node foundation."
  value = {
    cluster_name       = var.cluster_topology.cluster_name
    worker_shape       = var.worker_shape
    worker_ocpus       = var.worker_ocpus
    worker_memory_gbs  = var.worker_memory_gbs
    worker_groups      = sort(keys(local.oci_worker_node_groups))
    worker_instances   = sort(keys(local.worker_instance_plan))
    worker_subnet_refs = var.worker_subnet_refs
    workload_placement = var.workload_placement
    worker_placement   = var.worker_placement
    storage_class      = var.storage_class
    resource_mode      = local.oci_instance_resources_enabled ? "provider-backed-vm" : "contract-only-until-image-is-set"
  }
}
