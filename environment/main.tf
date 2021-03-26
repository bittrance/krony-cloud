locals {
  host                   = azurerm_kubernetes_cluster.krony_kube.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.krony_kube.kube_config.0.cluster_ca_certificate)
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "kubernetes" {
  host                   = local.host
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate
}

provider "kubernetes-alpha" {
  host                   = local.host
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = local.host
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca_certificate
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

data "azurerm_client_config" "current" {}

data "azurerm_dns_zone" "krony_cloud" {
  name = "krony.cloud"
}

resource "azurerm_resource_group" "krony_env" {
  name     = "krony-cloud-${var.env_name}"
  location = "West Europe"
}

resource "azurerm_dns_ns_record" "krony_subdomain" {
  name                = var.env_name
  zone_name           = data.azurerm_dns_zone.krony_cloud.name
  # TODO: The zone and the record has to be in the same RG?
  resource_group_name = "krony-cloud-global"
  ttl                 = 300
  records             = azurerm_dns_zone.krony_subdomain.name_servers
}

resource "azurerm_dns_zone" "krony_subdomain" {
  resource_group_name = azurerm_resource_group.krony_env.name
  name                = "${var.env_name}.krony.cloud"
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
