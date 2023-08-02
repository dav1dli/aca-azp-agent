output "id" {
  value = azurerm_container_app_environment.cap_environment.id
  description = "Specifies the resource id of the Container App Environment"
}

output "name" {
  value = azurerm_container_app_environment.cap_environment.name
  description = "Specifies the name of the Container App Environment"
}

output "default_domain" {
  value = azurerm_container_app_environment.cap_environment.default_domain
  description = "Specifies the default, publicly resolvable, name of the Container App Environment"
}
output "static_ip_address" {
  value = azurerm_container_app_environment.cap_environment.static_ip_address
  description = "Specifies the static IP of the Container App Environment"
}