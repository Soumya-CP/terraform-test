variable "name" {
  description = "Log Analytics Workspace name."
  type        = string
}

variable "location" {
  description = "Azure Region for the Log Analytics Workspace."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group containing the Log Analytics Workspace."
  type        = string
}

variable "retention_in_days" {
  description = "Log Analytics Workspace retention period in days."
  type        = number
}

variable "tags" {
  description = "Tags applied to the Log Analytics Workspace."
  type        = map(string)
}
