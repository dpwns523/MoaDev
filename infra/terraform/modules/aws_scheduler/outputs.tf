output "summary" {
  description = "Safe summary of the AWS dev scheduler skeleton."
  value = {
    enabled               = local.effective_enabled
    target_scope          = var.target_scope
    target_node_groups    = local.effective_enabled ? local.target_node_groups : []
    start_schedule        = local.effective_enabled ? var.start_schedule : ""
    stop_schedule         = local.effective_enabled ? var.stop_schedule : ""
    implementation_status = "skeleton-only"
  }
}
