terraform {
  required_version = ">= 1.5.0"
}

module "application" {
  source       = "../../modules/application"
  environment  = "dev"
  service_name = "moadev"
}

output "release_name" {
  value = module.application.release_name
}
