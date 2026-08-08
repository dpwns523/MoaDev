variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "enabled" {
  description = "Whether the AWS dev scheduler skeleton is enabled."
  type        = bool
}

variable "target_scope" {
  description = "Node group target scope for the scheduler."
  type        = string
}

variable "start_schedule" {
  description = "Start schedule placeholder or expression."
  type        = string
}

variable "stop_schedule" {
  description = "Stop schedule placeholder or expression."
  type        = string
}

variable "worker_node_group_names" {
  description = "AWS worker node groups managed by the scheduler."
  type        = list(string)
}

variable "control_plane_node_group_names" {
  description = "AWS control-plane node groups optionally managed by the scheduler."
  type        = list(string)
}
