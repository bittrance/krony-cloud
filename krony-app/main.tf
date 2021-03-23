locals {
  host                   = data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.cluster_ca_certificate)
}

variable "env_name" {
  default = "test"
}

provider "azurerm" {
  features {}
}

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

data "azurerm_kubernetes_cluster" "krony_kube" {
  name                = "krony-${var.env_name}-kubernetes"
  resource_group_name = "krony-cloud-${var.env_name}"
}
