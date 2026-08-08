terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0.0"
    }
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0, < 6.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_cluster.region
}

provider "oci" {
  region = var.oci_cluster.region
}

locals {
  # The directory chooses the environment so stage naming stays independent from provider selection.
  environment = "prod"

  default_aws_dev_scheduler = {
    enabled        = false
    target_scope   = "disabled"
    start_schedule = ""
    stop_schedule  = ""
  }

  aws_dev_scheduler = var.aws_dev_scheduler == null ? local.default_aws_dev_scheduler : var.aws_dev_scheduler
}

module "application" {
  source       = "../../modules/application"
  environment  = local.environment
  service_name = var.service_name
}

module "platform_contract" {
  source = "../../modules/platform_contract"

  environment       = local.environment
  service_name      = var.service_name
  platform_topology = var.platform_topology
  cluster_topology  = var.cluster_topology
  domains           = var.domains
  images            = var.images
  namespaces        = var.namespaces
  ingress           = var.ingress
  scheduling        = var.scheduling
  cicd              = var.cicd
  monitoring        = var.monitoring
  storage           = var.storage
  cost_automation   = var.cost_automation
  oci_cluster       = var.oci_cluster
  aws_cluster       = var.aws_cluster
}

module "shared_labels" {
  source = "../../modules/shared_labels"

  environment           = local.environment
  service_name          = var.service_name
  naming_prefix_pattern = var.shared_labels.naming_prefix_pattern
  labels                = var.shared_labels.labels
  cost_center           = var.cost_automation.cost_center
}

module "aws_network" {
  source = "../../modules/aws_network"

  environment                              = local.environment
  cluster_name                             = var.cluster_topology.cluster_name
  region                                   = var.aws_cluster.region
  network_mode                             = var.aws_cluster.network_mode
  name_prefix                              = module.shared_labels.name_prefix
  labels                                   = module.shared_labels.labels
  vpc_cidr                                 = var.aws_cluster.vpc_cidr
  availability_zones                       = var.aws_cluster.availability_zones
  control_plane_subnet_cidrs               = var.aws_cluster.control_plane_subnet_cidrs
  worker_subnet_cidrs                      = var.aws_cluster.worker_subnet_cidrs
  public_load_balancer_subnet_cidrs        = var.aws_cluster.public_load_balancer_subnet_cidrs
  existing_vpc_id                          = var.aws_cluster.vpc_id != null ? var.aws_cluster.vpc_id : ""
  existing_control_plane_subnet_ids        = var.aws_cluster.control_plane_subnet_ids
  existing_worker_subnet_ids               = var.aws_cluster.worker_subnet_ids
  existing_public_load_balancer_subnet_ids = var.aws_cluster.public_load_balancer_subnet_ids
  nat_gateway_enabled                      = var.aws_cluster.nat_gateway_enabled
  nat_gateway_mode                         = var.aws_cluster.nat_gateway_mode
  security_profile                         = var.aws_cluster.security_profile
  ssh_access_mode                          = var.aws_cluster.ssh_access_mode
  admin_ingress_cidrs                      = var.aws_cluster.admin_ingress_cidrs
  kube_api_access_mode                     = var.aws_cluster.kube_api_access_mode
  kube_api_ingress_cidrs                   = var.aws_cluster.kube_api_ingress_cidrs
  cluster_internal_cidrs                   = var.aws_cluster.cluster_internal_cidrs
}

module "oci_network" {
  source = "../../modules/oci_network"

  environment                     = local.environment
  cluster_name                    = var.cluster_topology.cluster_name
  region                          = var.oci_cluster.region
  compartment_ocid                = var.oci_cluster.compartment_ocid
  network_mode                    = var.oci_cluster.network_mode
  name_prefix                     = module.shared_labels.name_prefix
  labels                          = module.shared_labels.labels
  vcn_cidr                        = var.oci_cluster.vcn_cidr
  availability_domains            = var.oci_cluster.availability_domains
  worker_subnet_cidrs             = var.oci_cluster.worker_subnet_cidrs
  existing_vcn_ocid               = var.oci_cluster.vcn_ocid != null ? var.oci_cluster.vcn_ocid : ""
  existing_worker_subnet_bindings = var.oci_cluster.existing_worker_subnet_bindings
  nat_gateway_enabled             = var.oci_cluster.nat_gateway_enabled
  security_profile                = var.oci_cluster.security_profile
  ssh_access_mode                 = var.oci_cluster.ssh_access_mode
  admin_ingress_cidrs             = var.oci_cluster.admin_ingress_cidrs
  cluster_internal_cidrs          = var.oci_cluster.cluster_internal_cidrs
}

module "aws_compute_nodes" {
  source = "../../modules/aws_compute_nodes"

  cluster_topology                     = var.cluster_topology
  name_prefix                          = module.shared_labels.name_prefix
  labels                               = module.shared_labels.labels
  control_plane_instance_type          = var.aws_cluster.control_plane_instance_type
  worker_instance_type                 = var.aws_cluster.worker_instance_type
  control_plane_root_volume_gbs        = var.aws_cluster.control_plane_root_volume_gbs
  worker_root_volume_gbs               = var.aws_cluster.worker_root_volume_gbs
  worker_spot_enabled                  = var.aws_cluster.worker_spot_enabled
  storage_class                        = var.aws_cluster.storage_class
  control_plane_endpoint_access_intent = var.aws_cluster.control_plane_endpoint_access_intent
  control_plane_placement_intent       = var.aws_cluster.control_plane_placement_intent
  worker_placement_intent              = var.aws_cluster.worker_placement_intent
  control_plane_subnet_refs            = module.aws_network.control_plane_subnet_refs
  worker_subnet_refs                   = module.aws_network.worker_subnet_refs
  control_plane_security_group_ids     = module.aws_network.control_plane_security_group_ids
  worker_security_group_ids            = module.aws_network.worker_security_group_ids
  ami_id                               = var.aws_cluster.ami_id
  ssh_key_name                         = var.aws_cluster.ssh_key_name
  instance_profile_name                = var.aws_cluster.instance_profile_name
  bootstrap_template_path = (
    var.aws_cluster.bootstrap_template_path == null || trimspace(var.aws_cluster.bootstrap_template_path) == ""
    ? null
    : (
      startswith(var.aws_cluster.bootstrap_template_path, "/")
      ? var.aws_cluster.bootstrap_template_path
      : abspath("${path.root}/${var.aws_cluster.bootstrap_template_path}")
    )
  )
}

module "oci_compute_nodes" {
  source = "../../modules/oci_compute_nodes"

  cluster_topology          = var.cluster_topology
  compartment_ocid          = var.oci_cluster.compartment_ocid
  name_prefix               = module.shared_labels.name_prefix
  labels                    = module.shared_labels.labels
  worker_shape              = var.oci_cluster.worker_shape
  worker_ocpus              = var.oci_cluster.worker_ocpus
  worker_memory_gbs         = var.oci_cluster.worker_memory_gbs
  worker_boot_volume_gbs    = var.oci_cluster.worker_boot_volume_gbs
  workload_placement_intent = var.oci_cluster.workload_placement_intent
  worker_placement_intent   = var.oci_cluster.worker_placement_intent
  storage_class             = var.oci_cluster.storage_class
  worker_subnet_bindings    = module.oci_network.worker_subnet_bindings
  worker_nsg_ids            = module.oci_network.worker_nsg_ids
  image_ocid                = var.oci_cluster.image_ocid
  ssh_authorized_keys       = var.oci_cluster.ssh_authorized_keys
  bootstrap_template_path = (
    var.oci_cluster.bootstrap_template_path == null || trimspace(var.oci_cluster.bootstrap_template_path) == ""
    ? null
    : (
      startswith(var.oci_cluster.bootstrap_template_path, "/")
      ? var.oci_cluster.bootstrap_template_path
      : abspath("${path.root}/${var.oci_cluster.bootstrap_template_path}")
    )
  )
}

module "aws_scheduler" {
  source = "../../modules/aws_scheduler"

  environment                    = local.environment
  enabled                        = local.aws_dev_scheduler.enabled
  target_scope                   = local.aws_dev_scheduler.target_scope
  start_schedule                 = local.aws_dev_scheduler.start_schedule
  stop_schedule                  = local.aws_dev_scheduler.stop_schedule
  worker_node_group_names        = module.aws_compute_nodes.worker_node_group_names
  control_plane_node_group_names = module.aws_compute_nodes.control_plane_node_group_names
}

output "release_name" {
  value = module.application.release_name
}

output "platform_contract_summary" {
  value = module.platform_contract.summary
}

output "cluster_foundations_summary" {
  value = {
    shared_labels = module.shared_labels.summary
    aws_network   = module.aws_network.summary
    aws_compute   = module.aws_compute_nodes.summary
    oci_network   = module.oci_network.summary
    oci_compute   = module.oci_compute_nodes.summary
    aws_scheduler = module.aws_scheduler.summary
  }
}
