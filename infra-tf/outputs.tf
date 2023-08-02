output "env" {
  value = var.environment
}
output "location" {
  value = data.azurerm_resource_group.rg.location
}
output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}
output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "application_object_id" {
  value = data.azuread_application.app_registration.id
}

output "cap_name" {
  value = module.cap_environment.name
}
output "cap_static_ip" {
  value = module.cap_environment.static_ip_address
}
output "cap_default_domain" {
  value = module.cap_environment.default_domain
}