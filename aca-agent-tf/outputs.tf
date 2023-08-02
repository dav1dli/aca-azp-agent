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
output "container_app_environment_name" {
  value = data.azurerm_container_app_environment.aca_env.name
}
output "job_template_name" {
  value = "${local.aca_name}-template"
}