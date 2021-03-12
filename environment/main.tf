provider "azurerm" {
  features {
    
  }
}

variable "env_name" {
  default = "test"
}

locals {
  address_space = "10.0.0.0/16"
}

resource "azurerm_resource_group" "krony_env" {
  name = "krony-cloud-${var.env_name}"
  location = "West Europe"
}

resource "azurerm_dns_zone" "krony_cloud" {
  resource_group_name = azurerm_resource_group.krony_env.name
  name = "${var.env_name}.krony.cloud"
}

resource "azurerm_virtual_network" "krony_net" {
  name                = "krony-${var.env_name}"
  resource_group_name = azurerm_resource_group.krony_env.name
  location            = azurerm_resource_group.krony_env.location
  address_space       = [local.address_space]
}

resource "azurerm_subnet" "krony_subnet" {
  name                 = "krony-${var.env_name}"
  resource_group_name  = azurerm_resource_group.krony_env.name
  virtual_network_name = azurerm_virtual_network.krony_net.name
  address_prefixes     = [cidrsubnet(local.address_space, 8, 0)]
}

resource "azurerm_linux_virtual_machine_scale_set" "kubernetes" {
  name                = "kubernetes-${var.env_name}"
  resource_group_name = azurerm_resource_group.krony_env.name
  location            = azurerm_resource_group.krony_env.location
  sku                 = "Standard_B1s"
  instances           = 3
  zone_balance        = true
  zones               = ["1", "2", "3"]
  admin_username      = "kronyadmin"

  admin_ssh_key {
    username   = "kronyadmin"
    public_key = file("./ssh-keys/${var.env_name}.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = azurerm_subnet.krony_subnet.id
    }
  }
}