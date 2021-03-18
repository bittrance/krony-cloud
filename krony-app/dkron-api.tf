resource "kubernetes_ingress" "dkron" {
  metadata {
    name = "dkron-api"
  }
  spec {
    rule {
      host = "api.${var.env_name}.krony.cloud"
      http {
        path {
          backend {
            service_name = kubernetes_service.dkron.metadata.0.name
            service_port = "http"
          }
          path = "/"
        }
      }
    }
  }
}

resource "kubernetes_service" "dkron" {
  metadata {
    name = "dkron-api"
  }
  spec {
    selector = {
      app = "dkron-api"
    }
    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_deployment" "dkron" {
  metadata {
    name = "dkron"
    labels = {
      app = "dkron-api"
    }
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "dkron-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "dkron-api"
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
            "--retry-join", "provider=k8s" # TODO: https://github.com/distribworks/dkron/issues/924
          ]

          port {
            name           = "http"
            container_port = 8080
          }
        }
      }
    }
  }
}
