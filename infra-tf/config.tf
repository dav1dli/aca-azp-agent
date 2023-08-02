terraform {
  required_providers {
    azurerm    = {
      source   = "hashicorp/azurerm"
    }
    azapi = {
      source = "Azure/azapi"
    }
  }
  # backend "azurerm" {}
}
provider "azurerm" {
  features {}
}
provider "azapi" { }