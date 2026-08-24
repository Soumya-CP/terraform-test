output "name" {
  description = "Log Analytics Workspace name."
  value       = azurerm_log_analytics_workspace.this.name
}

output "id" {
  description = "Log Analytics Workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}

output "retention_in_days" {
  description = "Configured retention period."
  value       = azurerm_log_analytics_workspace.this.retention_in_days
}
