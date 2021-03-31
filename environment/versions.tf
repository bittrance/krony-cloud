terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "1.4.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.46.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "0.1.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.0.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.10.0"
    }
    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.3.2"
    }
    random = {
      source = "hashicorp/random"
      version = "3.1.0"
    }
  }
  required_version = ">= 0.14.0"
}
