resource "helm_release" "monitoring" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "14.2.0"
  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }
  set {
    name  = "grafana.ingress.hosts[0]"
    value = "admin.${var.env_name}.krony.cloud"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.proxy.enabled"
    value = "true"
  }
  set {
    name  = "grafana.grafana\\.ini.auth\\.proxy.header_name"
    value = "X-Remote-User"
  }
  set {
    name  = "grafana.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
    value = "web\\,websecure"
  }
  set {
    name  = "grafana.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares"
    value = "adminauth@file"
  }
}
