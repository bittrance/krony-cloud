variable "letsencrypt_email" {
  type = string
}

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
    type = "LoadBalancer"
    selector = {
      app = "traefik"
    }
    port {
      name = "http"
      port = 80
    }
    port {
      name = "https"
      port = 443
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
          image = "traefik:v2.4.7"
          name  = "traefik"
          args = [
            "--accesslog",
            "--providers.kubernetesingress.ingressendpoint.publishedservice=kube-system/traefik-ingress-controller",
            "--log.level=DEBUG",
            "--entrypoints.web.address=:80",
            "--entrypoints.web.http.redirections.entrypoint.to=websecure",
            "--entrypoints.websecure.address=:443",
            "--entrypoints.websecure.http.tls.certresolver=letsencrypt",
            # "--certificatesresolvers.letsencrypt.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory",
            "--certificatesresolvers.letsencrypt.acme.email=${var.letsencrypt_email}",
            "--certificatesresolvers.letsencrypt.acme.tlschallenge=true",
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
