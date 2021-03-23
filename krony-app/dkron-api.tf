resource "kubernetes_ingress" "dkron" {
  metadata {
    name = "dkron-api"
    annotations = {
      "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure"
      "traefik.ingress.kubernetes.io/router.middlewares" = "customerauth@file"
    }
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
          path = "/v1"
        }
      }
    }
  }
}

resource "kubernetes_service" "dkron" {
  metadata {
    name = "dkron-api"
    labels = {
      "app" = "dkron-api"
    }
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

resource "kubernetes_manifest" "dkron_metrics" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "dkron-metrics"
      namespace = "default"
      labels = {
        release = "kube-prometheus-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "dkron-api"
        }
      }
      endpoints = [
        {
          port = "http"
          path = "/metrics"
        },
      ]
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
            "--enable-prometheus",
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
