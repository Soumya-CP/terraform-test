variable "azure_location" {
  description = "Azure Region used for the demonstration resources."
  type        = string
  default     = "eastus"
}

variable "tenant_slug" {
  description = "Safe tenant identifier used in Azure resource names."
  type        = string
  default     = "artizent"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.tenant_slug))
    error_message = "tenant_slug must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Target environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "preprod", "prod"], lower(var.environment))
    error_message = "environment must be dev, preprod, or prod."
  }
}

variable "log_retention_days" {
  description = "Log Analytics Workspace retention period in days."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730 days."
  }
}

variable "release_version" {
  description = "Safe release marker used to demonstrate Terraform updates."
  type        = string
  default     = "v1"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.release_version))
    error_message = "release_version may contain only letters, numbers, dots, underscores, and hyphens."
  }
}

variable "owner" {
  description = "Resource owner tag."
  type        = string
  default     = "cloudops"
}

variable "create_demo_resource" {
  description = "Whether the demonstration Resource Group and Log Analytics Workspace should exist."
  type        = bool
  default     = true
}
