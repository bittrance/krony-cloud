provider "azurerm" {
  features {}
}

variable "env_name" {
  default = "test"
}

resource "azurerm_resource_group" "testing" {
  name     = "krony-cloud-testing-${var.env_name}"
  location = "West Europe"
}

resource "azurerm_container_registry" "webhook_receiver" {
  name                     = "webhook-receiver"
  resource_group_name      = azurerm_resource_group.testing.name
  location                 = azurerm_resource_group.testing.location
  sku                      = "Premium"
  admin_enabled            = false
  georeplication_locations = ["West Europe"]
}
