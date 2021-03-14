variable "env_name" {
  default = "test"
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "krony_kube" {
  name                = "krony-${var.env_name}-kubernetes"
  resource_group_name = "krony-cloud-${var.env_name}"
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.krony_kube.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_service" "dkron" {
  metadata {
    name = "dkron-api"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app         = "dkron-api"
      environment = var.env_name
    }
    port {
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_deployment" "dkron" {
  metadata {
    name = "dkron"
    labels = {
      app = "dkron-api"
      environment = var.env_name
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "dkron-api"
        environment = var.env_name
      }
    }
    template {
      metadata {
        labels = {
          app = "dkron-api"
          environment = var.env_name
        }
      }
      spec {
        container {
          image = "dkron/dkron:latest"
          name  = "dkron"
          args = [
            "agent",
            "--server",
            "--bootstrap-expect", "2",
            "--retry-join", "provider=k8s"
          ]

          port {
            container_port = 8080
          }

        #   liveness_probe {
        #     http_get {
        #       path = "/nginx_status"
        #       port = 80

        #       http_header {
        #         name  = "X-Custom-Header"
        #         value = "Awesome"
        #       }
        #     }

        #     initial_delay_seconds = 3
        #     period_seconds        = 3
        #   }
        }        
      }
    }
  }
}