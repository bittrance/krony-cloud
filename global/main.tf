provider "azurerm" {
  features {
    
  }
}

resource "azurerm_resource_group" "krony" {
  name = "krony-cloud-global"
  location = "West Europe"
}

resource "azurerm_dns_zone" "krony_cloud" {
  resource_group_name = azurerm_resource_group.krony.name
  name = "krony.cloud"
}