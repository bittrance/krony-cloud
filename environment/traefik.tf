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

resource "kubernetes_service" "traefik_metrics" {
  metadata {
    name      = "traefik-metrics"
    namespace = "kube-system"
    labels = {
      app = "traefik"
    }
  }
  spec {
    selector = {
      app = "traefik"
    }
    port {
      name = "metrics"
      port = 8080
    }
  }
}

resource "kubernetes_manifest" "traefik_metrics" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "traefik-metrics"
      namespace = "kube-system"
      labels = {
        release = "kube-prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "traefik"
        }
      }
      endpoints = [
        { port = "metrics" },
      ]
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
            "--entrypoints.metrics.address=:8080",
            "--metrics.prometheus.entrypoint=metrics",
            "--providers.file.filename=/config/traefik.toml",
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
          volume_mount {
            name       = "traefik-config"
            mount_path = "/config"
            read_only  = true
          }
        }
        volume {
          name = "traefik-config"
          config_map {
            name = "traefik-config"
          }
        }
      }
    }
  }
}

# TODO: This is not optimal, in particular not since it is the same list for all envs
resource "kubernetes_config_map" "traefik" {
  metadata {
    name      = "traefik-config"
    namespace = "kube-system"
  }
  data = {
    "traefik.toml" = <<-EOT
      [http.middlewares]
      [http.middlewares.customerauth.basicauth]
      removeheader = true
      users = [
        "bittrance:$2y$05$JOd.zJDDDiHhnp.gRIVHfu5LlYWda4dVduYUiefjd17mDS8xVZkru"
      ]
      [http.middlewares.adminauth.basicauth]
      headerField = "X-Remote-User"
      removeheader = true
      users = [
        "admin:$2y$05$JOd.zJDDDiHhnp.gRIVHfu5LlYWda4dVduYUiefjd17mDS8xVZkru"
      ]
    EOT
  }
}
