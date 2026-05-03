variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "cluster_name" {
  description = "Logical cluster name used in summaries."
  type        = string
}

variable "region" {
  description = "AWS region for the network foundation."
  type        = string
}

variable "network_mode" {
  description = "Whether to create new AWS network foundations or reference existing ones."
  type        = string
}

variable "name_prefix" {
  description = "Generated name prefix for AWS resources."
  type        = string
}

variable "labels" {
  description = "Shared labels propagated to the AWS network summary."
  type        = map(string)
}

variable "vpc_cidr" {
  description = "CIDR for a Terraform-managed VPC in create mode."
  type        = string
  default     = null
  nullable    = true
}

variable "availability_zones" {
  description = "Availability zones used when creating subnet layouts."
  type        = list(string)
  default     = []
}

variable "control_plane_subnet_cidrs" {
  description = "CIDRs for control-plane subnets in create mode."
  type        = list(string)
  default     = []
}

variable "worker_subnet_cidrs" {
  description = "CIDRs for worker subnets in create mode."
  type        = list(string)
  default     = []
}

variable "public_load_balancer_subnet_cidrs" {
  description = "CIDRs for public load-balancer subnets in create mode."
  type        = list(string)
  default     = []
}

variable "existing_vpc_id" {
  description = "Existing VPC identifier used in reference mode."
  type        = string
  default     = ""
}

variable "existing_control_plane_subnet_ids" {
  description = "Existing control-plane subnet identifiers used in reference mode."
  type        = list(string)
  default     = []
}

variable "existing_worker_subnet_ids" {
  description = "Existing worker subnet identifiers used in reference mode."
  type        = list(string)
  default     = []
}

variable "existing_public_load_balancer_subnet_ids" {
  description = "Existing public load-balancer subnet identifiers used in reference mode."
  type        = list(string)
  default     = []
}

variable "nat_gateway_enabled" {
  description = "Whether create mode should provision NAT egress for private subnets."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT egress topology for AWS private subnets."
  type        = string
  default     = "single"
}

variable "security_profile" {
  description = "Named security profile used to derive AWS node access rules."
  type        = string
  default     = "kubespray-default"
}

variable "ssh_access_mode" {
  description = "How operator SSH access should be modeled for AWS nodes."
  type        = string
  default     = "cidr_allowlist"
}

variable "admin_ingress_cidrs" {
  description = "Allowed admin ingress CIDRs for AWS node access."
  type        = list(string)
  default     = []
}

variable "kube_api_access_mode" {
  description = "How Kubernetes API access should be modeled for AWS control-plane nodes."
  type        = string
  default     = "private_only"
}

variable "kube_api_ingress_cidrs" {
  description = "Allowed CIDRs for Kubernetes API ingress when public allowlisting is used."
  type        = list(string)
  default     = []
}

variable "cluster_internal_cidrs" {
  description = "Cluster-internal CIDRs allowed for AWS node communication."
  type        = list(string)
  default     = []
}
