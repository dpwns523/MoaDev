locals {
  supported_label_values = {
    service     = var.service_name
    environment = var.environment
    track       = var.track
    managed_by  = var.managed_by
    cost_center = var.cost_center
  }

  labels = {
    for key in var.labels :
    key => local.supported_label_values[key]
  }

  name_prefix = replace(
    replace(var.naming_prefix_pattern, "{environment}", var.environment),
    "{service}",
    var.service_name,
  )
}

check "supported_label_keys" {
  assert {
    condition = alltrue([
      for key in var.labels :
      contains(keys(local.supported_label_values), key)
    ])
    error_message = "labels may only contain supported keys: service, environment, track, managed_by, cost_center."
  }
}
