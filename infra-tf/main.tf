data "azurerm_client_config" "current" {
}
data "azuread_application" "app_registration" {
  display_name = local.ad_app
}
data "azurerm_resource_group" "rg" {
  name = local.resource_group
}
data "azuread_service_principal" "ad_app_sp" {
  application_id = data.azuread_application.app_registration.application_id
}
resource "azurerm_role_assignment" "ad_app_role" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.ad_app_sp.object_id
}
module "log_analytics_workspace" {
  source                           = "./modules/analytics"
  name                             = local.log_analytics_workspace_name
  location                         = data.azurerm_resource_group.rg.location
  resource_group_name              = data.azurerm_resource_group.rg.name
}

module "vnet" {
  source              = "./modules/virtual_network"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  vnet_name           = local.vnet_name
  address_space       = var.vnet_address_space

  subnets = [
      {
        name : local.cap_subnet
        address_prefixes : var.cap_subnet_address_prefix
      },
      {
        name : local.priv_endpt_subnet
        address_prefixes : var.priv_endpt_subnet_address_prefix
      },
  ]
}
# ACR container registry ---------------------------------------------------------------
module "acr" {
  source                       = "./modules/acr"
  name                         = local.acr_name
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  sku                          = var.acr_sku
  admin_enabled                = var.acr_admin_enabled
}
module "acr_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.azurecr.io"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = data.azurerm_resource_group.rg.name
    }
  }
  depends_on                   = [ module.vnet ]
}
module "acr_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = local.acr_pep_name
  location                       = data.azurerm_resource_group.rg.location
  resource_group_name            = data.azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[local.priv_endpt_subnet]
  tags                           = var.tags
  private_connection_resource_id = module.acr.id
  is_manual_connection           = false
  subresource_name               = "registry"
  private_dns_zone_group_name    = "AcrPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.acr_private_dns_zone.id]
  depends_on                   = [ module.acr, module.vnet ]
}
# Key vault -----------------------------------------------------------------------------
module "key_vault" {
  source                          = "./modules/keyvault"
  name                            = local.kv_name
  location                        = data.azurerm_resource_group.rg.location
  resource_group_name             = data.azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.key_vault_sku_name
  tags                            = var.tags
  enabled_for_deployment          = var.key_vault_enabled_for_deployment
  enabled_for_disk_encryption     = var.key_vault_enabled_for_disk_encryption
  enabled_for_template_deployment = var.key_vault_enabled_for_template_deployment
  enable_rbac_authorization       = var.key_vault_enable_rbac_authorization
  purge_protection_enabled        = var.key_vault_purge_protection_enabled
  soft_delete_retention_days      = var.key_vault_soft_delete_retention_days
  bypass                          = var.key_vault_bypass
  default_action                  = var.key_vault_default_action
}
resource "azurerm_key_vault_access_policy" "opuser_kv_read" {
  key_vault_id       = module.key_vault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  key_permissions    = [ "Get", "List", "Encrypt", "Decrypt", "Create", "Update" ]
  secret_permissions = [ "Get", "List", "Set" ]
}
module "kv_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.vaultcore.azure.net"
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = data.azurerm_resource_group.rg.name
    }
  }
}
module "kv_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = local.kv_pep_name
  location                       = data.azurerm_resource_group.rg.location
  resource_group_name            = data.azurerm_resource_group.rg.name
  subnet_id                      = module.vnet.subnet_ids[local.priv_endpt_subnet]
  tags                           = var.tags
  private_connection_resource_id = module.key_vault.id
  is_manual_connection           = false
  subresource_name               = "vault"
  private_dns_zone_group_name    = "KeyVaultPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.kv_private_dns_zone.id]
}
# Container app environment ------------------------------------------------------------
module "cap_environment" {
  source                         = "./modules/cap_env"
  name                           = local.cap_name
  resource_group_name            = data.azurerm_resource_group.rg.name
  location                       = data.azurerm_resource_group.rg.location
  log_analytics_workspace_id     = module.log_analytics_workspace.id
  infrastructure_subnet_id       = module.vnet.subnet_ids[local.cap_subnet]
  internal_load_balancer_enabled = var.cap_private
  depends_on                     = [ module.log_analytics_workspace, module.vnet ]
}
module "cap_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = module.cap_environment.default_domain
  resource_group_name          = data.azurerm_resource_group.rg.name
  virtual_networks_to_link     = {
    (module.vnet.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = data.azurerm_resource_group.rg.name
    }
  }
  depends_on                   = [ module.vnet ]
}
resource "azurerm_private_dns_a_record" "cap_static_ip" {
  name                = "*"
  zone_name           = module.cap_environment.default_domain
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [ module.cap_environment.static_ip_address ]
  depends_on          = [ module.cap_private_dns_zone, module.cap_environment ]
}
resource "azurerm_user_assigned_identity" "cap_user_identity" {
  location            = data.azurerm_resource_group.rg.location
  name                = local.cap_user_identity
  resource_group_name = data.azurerm_resource_group.rg.name
}
resource "azurerm_key_vault_access_policy" "cap_kv_secret_read" {
  key_vault_id    = module.key_vault.id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  object_id       = azurerm_user_assigned_identity.cap_user_identity.principal_id
  secret_permissions = [ "Get", ]
}
resource "azurerm_role_assignment" "aca_acr" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.cap_user_identity.principal_id
}