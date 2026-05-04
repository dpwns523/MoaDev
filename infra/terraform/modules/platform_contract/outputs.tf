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
        control_plane_endpoint_access_intent = var.aws_cluster.control_plane_endpoint_access_intent
        control_plane_placement_intent       = var.aws_cluster.control_plane_placement_intent
        worker_placement_intent              = var.aws_cluster.worker_placement_intent
        bastion_enabled                      = var.aws_cluster.bastion_enabled
      }
      oci = {
        availability_domains      = var.oci_cluster.availability_domains
        workload_placement_intent = var.oci_cluster.workload_placement_intent
        worker_placement_intent   = var.oci_cluster.worker_placement_intent
        bastion_enabled           = var.oci_cluster.bastion_enabled
      }
    }
    provider_security = {
      aws = {
        security_profile       = var.aws_cluster.security_profile
        ssh_access_mode        = var.aws_cluster.ssh_access_mode
        kube_api_access_mode   = var.aws_cluster.kube_api_access_mode
        cluster_internal_cidrs = var.aws_cluster.cluster_internal_cidrs
      }
      oci = {
        security_profile       = var.oci_cluster.security_profile
        ssh_access_mode        = var.oci_cluster.ssh_access_mode
        cluster_internal_cidrs = var.oci_cluster.cluster_internal_cidrs
      }
    }
  }
}
