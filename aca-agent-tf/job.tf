resource "null_resource" "agent_delete" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      az containerapp job delete --name ${var.agent_config.name} \
        --resource-group ${local.resource_group} --yes > /dev/null
    EOT
  }
}

resource "null_resource" "agent_create" {
  depends_on = [null_resource.agent_delete]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
      az containerapp job create -n ${local.aca_name} \
        -g ${local.resource_group} \
        --environment ${local.aca_env_name} \
        --trigger-type Event \
        --replica-timeout 1800 --replica-retry-limit 1 \
        --replica-completion-count 1 --parallelism 1 \
        --image ${var.agent_config.image}:${var.agent_config.version} \
        --cpu ${var.agent_config.cpu} --memory ${var.agent_config.memory} \
        --min-executions 0 --max-executions 10 --polling-interval 30 \
        --scale-rule-name "azure-pipelines" --scale-rule-type "azure-pipelines" \
        --scale-rule-metadata "poolID=${var.agent_config.agent_pool_id}" "targetPipelinesQueueLength=1" \
        --scale-rule-auth "personalAccessToken=azp-token" "organizationURL=organization-url" \
        --secrets "azp-token=${data.azurerm_key_vault_secret.azptoken.value}" \
        "organization-url=${var.agent_config.azp_url}" "acrpassword=${data.azurerm_container_registry.acr.admin_password}" \
        --env-vars AZP_URL=${var.agent_config.azp_url} AZP_POOL=${var.agent_config.agent_pool} "AZP_TOKEN=secretref:azp-token" \
        --registry-server ${data.azurerm_container_registry.acr.login_server}  \
        --registry-username ${data.azurerm_container_registry.acr.admin_username} \
        --registry-password "secretref:acrpassword"
    EOT
  }
}
output "job_name" {
  value = local.aca_name
}