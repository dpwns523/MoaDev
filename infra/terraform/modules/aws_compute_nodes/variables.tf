variable "cluster_topology" {
  description = "Shared cluster topology contract."
  type = object({
    cluster_name           = string
    kubernetes_version     = string
    control_plane_provider = string
    cni_plugin             = string
    pod_cidr               = string
    service_cidr           = string
    node_groups = map(object({
      provider         = string
      role             = string
      desired_count    = number
      min_count        = number
      max_count        = number
      scaling_strategy = string
    }))
  })
}

variable "name_prefix" {
  description = "Generated name prefix for AWS compute resources."
  type        = string
}

variable "labels" {
  description = "Shared labels for AWS compute resources."
  type        = map(string)
}

variable "control_plane_instance_type" {
  description = "Instance type for AWS control-plane nodes."
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for AWS worker nodes."
  type        = string
}

variable "control_plane_root_volume_gbs" {
  description = "Root volume size for AWS control-plane nodes."
  type        = number
}

variable "worker_root_volume_gbs" {
  description = "Root volume size for AWS worker nodes."
  type        = number
}

variable "worker_spot_enabled" {
  description = "Whether AWS worker nodes may use spot capacity."
  type        = bool
}

variable "storage_class" {
  description = "Storage class name shared with AWS node groups."
  type        = string
}

variable "control_plane_endpoint_access_intent" {
  description = "Endpoint exposure intent for AWS control-plane nodes."
  type        = string
}

variable "control_plane_placement_intent" {
  description = "Placement intent for AWS control-plane nodes."
  type        = string
}

variable "worker_placement_intent" {
  description = "Placement intent for AWS worker nodes."
  type        = string
}

variable "control_plane_subnet_refs" {
  description = "Control-plane subnet references for AWS node groups."
  type        = list(string)
}

variable "worker_subnet_refs" {
  description = "Worker subnet references for AWS node groups."
  type        = list(string)
}

variable "control_plane_security_group_ids" {
  description = "Security groups attached to AWS control-plane nodes."
  type        = list(string)
}

variable "worker_security_group_ids" {
  description = "Security groups attached to AWS worker nodes."
  type        = list(string)
}

variable "ami_id" {
  description = "AMI used for AWS VM nodes."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_key_name" {
  description = "SSH key pair name attached to AWS VM nodes."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_profile_name" {
  description = "IAM instance profile name attached to AWS VM nodes."
  type        = string
  default     = null
  nullable    = true
}

variable "bootstrap_template_path" {
  description = "Path to the cloud-init or user-data template for AWS VM nodes."
  type        = string
  default     = null
  nullable    = true
}
