provider "azurerm" {
  features {
    
  }
}

variable "env_name" {
  default = "test"
}


output "client_certificate" {
  value = azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.krony_kube.kube_config_raw
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


resource "azurerm_kubernetes_cluster" "krony_kube" {
  name                = "krony-${var.env_name}-kubernetes"
  resource_group_name = azurerm_resource_group.krony_env.name
  location            = azurerm_resource_group.krony_env.location
  dns_prefix          = "krony-${var.env_name}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_public_ip" "krony_bastion" {
  name                = "krony-${var.env_name}-bastion"
  resource_group_name = azurerm_resource_group.krony_env.name
  location            = azurerm_resource_group.krony_env.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "krony_bastion" {
  name                = "krony-${var.env_name}-bastion"
  location            = azurerm_resource_group.krony_env.location
  resource_group_name = azurerm_resource_group.krony_env.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.krony_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.krony_bastion.id
  }
}

resource "azurerm_linux_virtual_machine" "krony_bastion" {
  name                = "krony-${var.env_name}-bastion"
  resource_group_name = azurerm_resource_group.krony_env.name
  location            = azurerm_resource_group.krony_env.location
  size                = "Standard_B1s"
  admin_username      = "kronyadmin"
  network_interface_ids = [
    azurerm_network_interface.krony_bastion.id,
  ]

  admin_ssh_key {
    username   = "kronyadmin"
    public_key = file("./ssh-keys/${var.env_name}.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}