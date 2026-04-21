output "vpc_ref" {
  description = "Reference to the VPC foundation, either a planned name or an existing VPC ID."
  value       = local.vpc_ref
}

output "control_plane_subnet_refs" {
  description = "Control-plane subnet references, either planned names or existing IDs."
  value       = local.control_plane_subnet_refs
}

output "worker_subnet_refs" {
  description = "Worker subnet references, either planned names or existing IDs."
  value       = local.worker_subnet_refs
}

output "public_load_balancer_subnet_refs" {
  description = "Public load-balancer subnet references, either planned names or existing IDs."
  value       = local.public_load_balancer_subnet_refs
}

output "summary" {
  description = "Safe summary of the AWS network skeleton."
  value = {
    environment                        = var.environment
    cluster_name                       = var.cluster_name
    region                             = var.region
    network_mode                       = var.network_mode
    vpc_ref                            = local.vpc_ref
    availability_zones                 = var.availability_zones
    control_plane_subnet_layout        = local.control_plane_subnet_plan
    control_plane_subnet_refs          = local.control_plane_subnet_refs
    worker_subnet_layout               = local.worker_subnet_plan
    worker_subnet_refs                 = local.worker_subnet_refs
    public_load_balancer_subnet_layout = local.public_load_balancer_subnet_plan
    public_load_balancer_subnet_refs   = local.public_load_balancer_subnet_refs
    labels                             = var.labels
  }
}
