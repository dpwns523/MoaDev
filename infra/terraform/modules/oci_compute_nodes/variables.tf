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

variable "compartment_ocid" {
  description = "OCI compartment OCID used for worker VM foundations."
  type        = string
}

variable "name_prefix" {
  description = "Generated name prefix for OCI compute resources."
  type        = string
}

variable "labels" {
  description = "Shared labels for OCI compute resources."
  type        = map(string)
}

variable "worker_shape" {
  description = "Shape for OCI worker nodes."
  type        = string
}

variable "worker_ocpus" {
  description = "OCPU count for OCI worker nodes."
  type        = number
}

variable "worker_memory_gbs" {
  description = "Memory size for OCI worker nodes."
  type        = number
}

variable "worker_boot_volume_gbs" {
  description = "Boot volume size for OCI worker nodes."
  type        = number
}

variable "workload_placement_intent" {
  description = "Workload placement intent for OCI worker nodes."
  type        = string
}

variable "worker_placement_intent" {
  description = "Network placement intent for OCI worker nodes."
  type        = string
}

variable "storage_class" {
  description = "Storage class name shared with OCI worker nodes."
  type        = string
}

variable "worker_subnet_bindings" {
  description = "Worker subnet bindings for OCI node groups."
  type = list(object({
    subnet_id           = string
    availability_domain = string
  }))
}

variable "worker_nsg_ids" {
  description = "NSG identifiers attached to OCI worker instances."
  type        = list(string)
}

variable "image_ocid" {
  description = "OCI image OCID used for worker VM nodes."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_authorized_keys" {
  description = "SSH public keys injected into OCI VM nodes."
  type        = string
  default     = null
  nullable    = true
}

variable "bootstrap_template_path" {
  description = "Path to the cloud-init or user-data template for OCI VM nodes."
  type        = string
  default     = null
  nullable    = true
}
