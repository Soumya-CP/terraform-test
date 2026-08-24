locals {
  normalized_tenant_slug = lower(var.tenant_slug)
  normalized_environment = lower(var.environment)
  name_prefix            = "ficp-${local.normalized_tenant_slug}-${local.normalized_environment}"

  resource_group_name = "rg-${local.name_prefix}-drift-demo"
  workspace_name      = "law-${local.name_prefix}-drift-demo"

  common_tags = {
    Name        = "ficp-drift-demo"
    Project     = "FICP"
    Workload    = "LogAnalytics"
    Tenant      = local.normalized_tenant_slug
    Environment = local.normalized_environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Release     = var.release_version
    DriftDemo   = "true"
  }
}

resource "azurerm_resource_group" "drift_demo" {
  count = var.create_demo_resource ? 1 : 0

  name     = local.resource_group_name
  location = var.azure_location
  tags     = local.common_tags
}

module "drift_demo_log_workspace" {
  count = var.create_demo_resource ? 1 : 0

  source = "./modules/log-analytics-workspace"

  name                = local.workspace_name
  location            = azurerm_resource_group.drift_demo[0].location
  resource_group_name = azurerm_resource_group.drift_demo[0].name
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}
