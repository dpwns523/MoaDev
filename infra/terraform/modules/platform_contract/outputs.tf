output "summary" {
  description = "Safe summary of the validated platform contract."
  value = {
    environment            = var.environment
    service_name           = var.service_name
    platform_topology      = var.platform_topology
    cluster_name           = var.cluster_topology.cluster_name
    kubernetes_version     = var.cluster_topology.kubernetes_version
    control_plane_provider = var.cluster_topology.control_plane_provider
    control_plane_groups   = sort(keys(local.control_plane_node_groups))
    worker_groups          = sort(keys(local.worker_node_groups))
    default_node_group     = var.scheduling.default_node_group
    load_balancer_provider = var.ingress.load_balancer_provider
    providers_in_use       = local.providers_in_use
    provider_regions = {
      aws = var.aws_cluster.region
      oci = var.oci_cluster.region
    }
    network_modes = {
      aws = var.aws_cluster.network_mode
      oci = var.oci_cluster.network_mode
    }
    provider_placement = {
      aws = {
        control_plane_endpoint_access = var.aws_cluster.control_plane_endpoint_access
        control_plane_placement       = var.aws_cluster.control_plane_placement
        worker_placement              = var.aws_cluster.worker_placement
        bastion_enabled               = var.aws_cluster.bastion_enabled
      }
      oci = {
        availability_domains = var.oci_cluster.availability_domains
        worker_placement     = var.oci_cluster.worker_placement
        bastion_enabled      = var.oci_cluster.bastion_enabled
      }
    }
  }
}
