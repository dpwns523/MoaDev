locals {
  effective_enabled = var.enabled && var.target_scope != "disabled"
  target_node_groups = var.target_scope == "include_control_plane" ? concat(
    var.worker_node_group_names,
    var.control_plane_node_group_names,
  ) : var.worker_node_group_names
}

check "scheduler_scope_is_supported" {
  assert {
    condition     = contains(["workers_only", "include_control_plane", "disabled"], var.target_scope)
    error_message = "target_scope must be workers_only, include_control_plane, or disabled."
  }
}

check "scheduler_only_runs_in_dev" {
  assert {
    condition     = !local.effective_enabled || var.environment == "dev"
    error_message = "The AWS dev scheduler skeleton may only be enabled in the dev environment."
  }
}

check "enabled_scheduler_has_schedules" {
  assert {
    condition = (
      !local.effective_enabled ||
      (
        trimspace(var.start_schedule) != "" &&
        trimspace(var.stop_schedule) != ""
      )
    )
    error_message = "Enabled AWS scheduler skeletons require non-empty start and stop schedules."
  }
}

check "enabled_scheduler_has_targets" {
  assert {
    condition     = !local.effective_enabled || length(local.target_node_groups) > 0
    error_message = "Enabled AWS scheduler skeletons require at least one target node group."
  }
}
