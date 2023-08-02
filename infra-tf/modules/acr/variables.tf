variable "name" {
  description = "(Required) Specifies the name of the Container Registry. Changing this forces a new resource to be created."
  type        = string
}
variable "resource_group_name" {
  description = "(Required) The name of the resource group in which to create the Container Registry. Changing this forces a new resource to be created."
  type        = string
}
variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}
variable "admin_enabled" {
  description = "(Optional) Specifies whether the admin user is enabled."
  type        = string
  default     = true
}
variable "sku" {
  description = "(Optional) The SKU name of the container registry. Possible values are Basic, Standard and Premium. Defaults to Basic"
  type        = string
  default     = "Standard"

  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The container registry sku is invalid."
  }
}
variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  type        = map(any)
  default     = {}
}