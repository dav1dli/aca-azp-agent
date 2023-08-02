data "azurerm_client_config" "current" {
}
data "azuread_application" "app_registration" {
  display_name = local.ad_app_name
}
data "azuread_service_principal" "ad_app_sp" {
  application_id = data.azuread_application.app_registration.application_id
}
data "azurerm_resource_group" "rg" {
  name = local.resource_group
}
data "azurerm_key_vault" "kv" {
  name                = local.kv_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_container_app_environment" "aca_env" {
  name                = local.aca_env_name
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_user_assigned_identity" "aca_user_identity" {
  name                = local.aca_user_identity
  resource_group_name = data.azurerm_resource_group.rg.name
}
data "azurerm_key_vault_secret" "azptoken" {
  name         = "AZDO-PAT"
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "null_resource" "agent_template_delete" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      az containerapp job delete --name ${var.agent_config.name}-template \
        --resource-group ${local.resource_group} --yes > /dev/null
    EOT
  }
}
resource "azapi_resource" "template" {
  type           = "Microsoft.App/jobs@2022-11-01-preview"
  name           = "${var.agent_config.name}-template"
  location       = data.azurerm_resource_group.rg.location
  parent_id      = data.azurerm_resource_group.rg.id
  tags           = var.tags
  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.aca_user_identity.id]
  }
  body = jsonencode({
    properties = {
      environmentId = data.azurerm_container_app_environment.aca_env.id
      configuration = {
        registries = [
          {
            server            = data.azurerm_container_registry.acr.login_server
            username          = data.azurerm_container_registry.acr.admin_username
            passwordSecretRef = "acrpassword"
          }
        ]
        triggerType              = "Manual"
        replicaRetryLimit        = 1
        replicaTimeout           = 300
        manualTriggerConfig      = {
          parallelism            = 1
          replicaCompletionCount = 1
        }
        secrets = [
          {
            name  = "acrpassword"
            value = data.azurerm_container_registry.acr.admin_password
          },
          {
            name  = "azptoken"
            value = data.azurerm_key_vault_secret.azptoken.value
          }
        ]
      }

      template = {
        containers = [
          {
            image         = "${var.agent_config.image}:${var.agent_config.version}"
            name          = "${var.agent_config.name}-template"
            env           = [
              {
                name      = "AZP_TOKEN"
                secretRef = "azptoken"
              },
              {
                name      = "AZP_URL"
                value     = "${var.agent_config.azp_url}"
              },
              {
                name      = "AZP_POOL"
                value     = "${var.agent_config.agent_pool}"
              },
              {
                name      = "AZP_POOLID"
                value     = "${var.agent_config.agent_pool_id}"
              },
              {
                name      = "AZP_AGENT_NAME"
                value     = "${var.agent_config.name}-template"
              }
            ]
            resources = {
              cpu         = var.agent_config.cpu
              memory      = var.agent_config.memory
            }
          }
        ]
      }
    }
  })
  lifecycle {
    ignore_changes = [
        tags
    ]
  }
  depends_on = [null_resource.agent_template_delete]
}
resource "null_resource" "agent_template_init" {
  depends_on = [azapi_resource.template]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      az containerapp job start --name ${local.aca_name}-template \
        --resource-group ${local.resource_group}
    EOT
  }
}

# The configuration fails. GitHub issue https://github.com/microsoft/azure-container-apps/issues/861
# Use null_resource calling az cli meanwhile. See job.tf .
# resource "azapi_resource" "agent" {
#   type                      = "Microsoft.App/jobs@2022-11-01-preview"
#   name                      = var.agent_config.name
#   location                  = data.azurerm_resource_group.rg.location
#   parent_id                 = data.azurerm_resource_group.rg.id
#   schema_validation_enabled = false
#   tags                      = var.tags
#   identity {
#     type         = "UserAssigned"
#     identity_ids = [data.azurerm_user_assigned_identity.aca_user_identity.id]
#   }
#   body = jsonencode({
#     properties = {
#       environmentId = data.azurerm_container_app_environment.aca_env.id
#       configuration = {
#         registries = [
#           {
#             server            = data.azurerm_container_registry.acr.login_server
#             username          = data.azurerm_container_registry.acr.admin_username
#             passwordSecretRef = "acrpassword"
#           }
#         ]
#         triggerType              = "Event"
#         replicaTimeout           = var.agent_config.timeout
#         replicaRetryLimit        = 1
#         eventTriggerConfig       = {
#           replicaCompletionCount = 1
#           parallelism            = 1
#           scale                  = {
#             minExecutions        = 0
#             maxExecutions        = var.agent_config.max_replicas
#             pollingInterval      = var.agent_config.polling_interval
#             rules = [
#               {
#                 name             = "azure-pipelines"
#                 type             = "azure-pipelines",
#                 metadata         = {
#                   demands                    = join(",", var.agent_config.capabilities)
#                   poolID                     = var.agent_config.agent_pool_id
#                   targetPipelinesQueueLength = "1"
#                 },
#                 auth = [
#                   {
#                     secretRef        = "azp-token"
#                     triggerParameter = "personalAccessToken"
#                   },
#                   {
#                     secretRef        = "organization-url"
#                     triggerParameter = "organizationURL"
#                   }
#                 ]
#               }
#             ]
#           }
#         }
#         secrets = [
#           {
#             name  = "acrpassword"
#             value = data.azurerm_container_registry.acr.admin_username
#           },
#           {
#             name  = "organization-url"
#             value = "${var.agent_config.azp_url}"
#           },
#           {
#             name  = "azp-token"
#             value = data.azurerm_key_vault_secret.azptoken.value
#           }
#         ]
#       }

#       template = {
#         containers = [
#           {
#             image         = "${var.agent_config.image}:${var.agent_config.version}"
#             name          = var.agent_config.name
#             env           = [
#               {
#                 name      = "AZP_TOKEN"
#                 secretRef = "azp-token"
#               },
#               {
#                 name      = "AZP_URL"
#                 value     = "${var.agent_config.azp_url}"
#               },
#               {
#                 name      = "AZP_POOL"
#                 value     = "${var.agent_config.agent_pool}"
#               },
#               {
#                 name      = "AZP_POOLID"
#                 value     = "${var.agent_config.agent_pool_id}"
#               },
#               {
#                 name      = "AZP_AGENT_NAME"
#                 value     = var.agent_config.name
#               }
#             ]
#             resources = {
#               cpu         = var.agent_config.cpu
#               memory      = var.agent_config.memory
#             }
#           }
#         ]
#       }
#     }
#   })
#   lifecycle {
#     ignore_changes = [
#         tags
#     ]
#   }
# }