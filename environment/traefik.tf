resource "kubernetes_service_account" "traefik" {
  metadata {
    name      = "traefik-ingress-controller"
    namespace = "kube-system"
  }
}

resource "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik-ingress-controller"
    namespace = "kube-system"
  }
  spec {
    selector = {
      app = "traefik"
    }
    port {
      name = "http"
      port = 80
    }
  }
}

resource "kubernetes_daemonset" "traefik" {
  metadata {
    name      = "traefik-ingress-controller"
    namespace = "kube-system"
    labels = {
      app = "traefik"
    }
  }
  spec {
    selector {
      match_labels = {
        app = "traefik"
      }
    }
    template {
      metadata {
        labels = {
          app  = "traefik"
          name = "traefik"
        }
      }
      spec {
        service_account_name             = "traefik-ingress-controller"
        termination_grace_period_seconds = 60
        container {
          image = "traefik:v1.7"
          name  = "traefik"
          args = [
            # "--api",
            "--kubernetes",
            "--logLevel=INFO",
          ]
          port {
            name           = "http"
            container_port = 80
            host_port      = 80
          }
          security_context {
            capabilities {
              drop = ["ALL"]
              add  = ["NET_BIND_SERVICE"]
            }
          }
        }
      }
    }
  }
}