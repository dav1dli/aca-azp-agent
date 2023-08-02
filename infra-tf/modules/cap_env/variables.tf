variable "resource_group_name" {
  description = "(Required) Specifies the resource group name"
  type = string
}

variable "location" {
  description = "(Required) Specifies the location of the Container App Environment"
  type = string
}

variable "name" {
  description = "(Required) Specifies the name of the Container App Environment"
  type = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace which the OMS Agent should send data to. Must be present if enabled is true."
  type        = string
}
variable "infrastructure_subnet_id" {
  description = "The ID of an existing subnet to use for the Container Apps Control Plane"
  type        = string
}
variable "internal_load_balancer_enabled" {
  description = "Container Apps exposed on internal load balancer."
  type        = bool
  default     = true
}
variable "tags" {
  description = "(Optional) Specifies the tags of the log analytics workspace"
  type        = map(any)
  default     = {}
}
