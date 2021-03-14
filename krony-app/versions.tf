terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.46.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.2"
    }
  }
  required_version = ">= 0.14.0"
}
