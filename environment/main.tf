provider "azurerm" {
  features {
    
  }
}

variable "env_name" {
  default = "test"
}

resource "azurerm_resource_group" "krony_env" {
  name = "krony-cloud-${var.env_name}"
  location = "West Europe"
}

resource "azurerm_dns_zone" "krony_cloud" {
  resource_group_name = azurerm_resource_group.krony_env.name
  name = "${var.env_name}.krony.cloud"
}