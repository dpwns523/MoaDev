output "vcn_ref" {
  description = "Reference to the VCN foundation, either a planned name or an existing VCN OCID."
  value       = local.vcn_ref
}

output "worker_subnet_refs" {
  description = "Worker subnet references, either planned names or existing OCIDs."
  value       = local.worker_subnet_refs
}

output "summary" {
  description = "Safe summary of the OCI network skeleton."
  value = {
    environment          = var.environment
    cluster_name         = var.cluster_name
    region               = var.region
    network_mode         = var.network_mode
    vcn_ref              = local.vcn_ref
    availability_domains = var.availability_domains
    worker_subnet_layout = local.worker_subnet_plan
    worker_subnet_refs   = local.worker_subnet_refs
    labels               = var.labels
  }
}
