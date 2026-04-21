variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "cluster_name" {
  description = "Logical cluster name used in summaries."
  type        = string
}

variable "region" {
  description = "OCI region for the network foundation."
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID used when creating VCN and subnet resources."
  type        = string
}

variable "network_mode" {
  description = "Whether to create new OCI network foundations or reference existing ones."
  type        = string
}

variable "name_prefix" {
  description = "Generated name prefix for OCI resources."
  type        = string
}

variable "labels" {
  description = "Shared labels propagated to the OCI network summary."
  type        = map(string)
}

variable "vcn_cidr" {
  description = "CIDR for a Terraform-managed VCN in create mode."
  type        = string
  default     = null
  nullable    = true
}

variable "availability_domains" {
  description = "Availability domains used when creating OCI subnet layouts."
  type        = list(string)
  default     = []
}

variable "worker_subnet_cidrs" {
  description = "CIDRs for OCI worker subnets in create mode."
  type        = list(string)
  default     = []
}

variable "existing_vcn_ocid" {
  description = "Existing VCN OCID used in reference mode."
  type        = string
  default     = ""
}

variable "existing_worker_subnet_ocids" {
  description = "Existing worker subnet OCIDs used in reference mode."
  type        = list(string)
  default     = []
}
