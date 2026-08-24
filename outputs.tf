output "demo_resource_created" {
  description = "Whether the demonstration Azure resources are enabled."
  value       = var.create_demo_resource
}

output "resource_group_name" {
  description = "Azure Resource Group name."
  value       = try(azurerm_resource_group.drift_demo[0].name, null)
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name."
  value       = try(module.drift_demo_log_workspace[0].name, null)
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID."
  value       = try(module.drift_demo_log_workspace[0].id, null)
}

output "configured_retention_days" {
  description = "Retention period declared in Git/Terraform."
  value       = var.log_retention_days
}

output "release_version" {
  description = "Release marker declared in Git/Terraform."
  value       = var.release_version
}
