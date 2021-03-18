resource "azuread_application" "external_dns" {
  display_name = "krony-${var.env_name}-external_dns"
}

resource "azuread_service_principal" "external_dns" {
  application_id = azuread_application.external_dns.application_id
}

resource "azuread_application_password" "external_dns" {
  application_object_id = azuread_application.external_dns.id
  value                 = random_password.external_dns.result
  end_date              = timeadd(timestamp(), "87600h") # 10 years

  lifecycle {
    ignore_changes = [
      end_date
    ]
  }
}

resource "random_password" "external_dns" {
  length           = 48
  special          = true
  override_special = "!-_="

  keepers = {
    service_principal = azuread_service_principal.external_dns.id
  }
}

resource "azurerm_role_assignment" "external_dns" {
  # TODO: This is not really the right scope
  scope                = azurerm_resource_group.krony_env.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.external_dns.object_id
}

resource "kubernetes_deployment" "external_dns" {
  metadata {
    name = "external-dns"
  }

  spec {
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app = "external-dns"
      }
    }
    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }
      spec {
        container {
          image = "k8s.gcr.io/external-dns/external-dns:v0.7.6"
          name  = "external-dns"
          args = [
            "--source=service",
            "--source=ingress",
            "--domain-filter=${azurerm_dns_zone.krony_subdomain.name}",
            "--provider=azure",
            # "--azure-resource-group=${azurerm_resource_group.krony_env.name}",
          ]
          volume_mount {
            name       = "external-dns-credentials"
            mount_path = "/etc/kubernetes"
            read_only  = true
          }
        }
        volume {
          name = "external-dns-credentials"
          secret {
            secret_name = kubernetes_secret.external_dns.metadata.0.name
          }
        }
      }
    }
  }
}

# TODO: No cleartext secrets, yo!
resource "kubernetes_secret" "external_dns" {
  metadata {
    name = "external-dns-credentials"
  }

  data = {
    "azure.json" = jsonencode({
      tenantId        = data.azurerm_client_config.current.tenant_id
      subscriptionId  = data.azurerm_client_config.current.subscription_id
      resourceGroup   = azurerm_resource_group.krony_env.name
      aadClientId     = azuread_service_principal.external_dns.application_id
      aadClientSecret = random_password.external_dns.result
    })
  }
}

