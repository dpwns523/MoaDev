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

variable "existing_worker_subnet_bindings" {
  description = "Existing worker subnet bindings used in reference mode."
  type = list(object({
    subnet_id           = string
    availability_domain = string
  }))
  default = []
}

variable "nat_gateway_enabled" {
  description = "Whether create mode should provision NAT egress for OCI private subnets."
  type        = bool
  default     = true
}

variable "security_profile" {
  description = "Named security profile used to derive OCI node access rules."
  type        = string
  default     = "kubespray-default"
}

variable "ssh_access_mode" {
  description = "How operator SSH access should be modeled for OCI nodes."
  type        = string
  default     = "cidr_allowlist"
}

variable "admin_ingress_cidrs" {
  description = "Allowed admin ingress CIDRs for OCI node access."
  type        = list(string)
  default     = []
}

variable "cluster_internal_cidrs" {
  description = "Cluster-internal CIDRs allowed for OCI node communication."
  type        = list(string)
  default     = []
}
