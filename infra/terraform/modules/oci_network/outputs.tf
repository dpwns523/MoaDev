output "vcn_ref" {
  description = "Reference to the VCN foundation, either a planned name or an existing VCN OCID."
  value       = local.vcn_ref
}

output "worker_subnet_bindings" {
  description = "Worker subnet bindings, either planned subnet/AD pairs or existing OCID bindings."
  value       = local.worker_subnet_bindings
}

output "worker_nsg_ids" {
  description = "NSG identifiers attached to OCI worker instances."
  value       = [oci_core_network_security_group.worker.id]
}

output "summary" {
  description = "Safe summary of the OCI network skeleton."
  value = {
    environment            = var.environment
    cluster_name           = var.cluster_name
    region                 = var.region
    network_mode           = var.network_mode
    vcn_ref                = local.vcn_ref
    availability_domains   = var.availability_domains
    worker_subnet_layout   = local.worker_subnet_plan
    worker_subnet_bindings = local.worker_subnet_bindings
    worker_nsg_ids         = [oci_core_network_security_group.worker.id]
    private_egress_mode    = local.nat_gateway_mode
    security_profile       = var.security_profile
    ssh_access_mode        = var.ssh_access_mode
    labels                 = var.labels
  }
}
