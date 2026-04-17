terraform {
  required_version = ">= 1.5.0"
}

locals {
  # The directory chooses the environment so stage naming stays independent from provider selection.
  environment = "prod"
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

output "release_name" {
  value = module.application.release_name
}

output "platform_contract_summary" {
  value = module.platform_contract.summary
}
