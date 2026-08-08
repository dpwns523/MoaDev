output "labels" {
  description = "Rendered shared label map based on the selected label keys."
  value       = local.labels
}

output "name_prefix" {
  description = "Generated prefix used by downstream modules when naming resources."
  value       = local.name_prefix
}

output "summary" {
  description = "Safe summary of the shared labels module output."
  value = {
    name_prefix = local.name_prefix
    label_keys  = sort(keys(local.labels))
  }
}
