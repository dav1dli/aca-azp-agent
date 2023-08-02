# Virtual Network for k8s internal network resources. Not accressible outside of the cluster 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
  required_version = ">= 0.14.9"
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    ignore_changes = [
        tags
    ]
  }
}

resource "azurerm_subnet" "subnet" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
  lifecycle {
    ignore_changes = [
        delegation
    ]
  }
  # dynamic "delegation" {
  #   for_each = lookup(each.value, "delegation", {}) != {} ? [1] : []
  #   content {
  #     name = lookup(each.value.delegation, "name", null)
  #     service_delegation {
  #       name    = lookup(each.value.delegation.service_delegation, "name", null)
  #       actions = lookup(each.value.delegation.service_delegation, "actions", null)
  #     }
  #   }
  # }
}