terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  retention_in_days   = var.retention_days
  tags                = var.tags
  lifecycle {
      ignore_changes = [
          tags
      ]
  }
}