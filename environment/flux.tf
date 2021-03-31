variable "github_slug" {
  type    = string
  default = "bittrance/krony-cloud"
}

variable "flux_github_token" {
  type      = string
  sensitive = true
}

locals {
  target_path = "clusters/${var.env_name}"
  apply = [for v in data.kubectl_file_documents.apply.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
  sync = [for v in data.kubectl_file_documents.sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
}

data "flux_install" "main" {
  target_path    = local.target_path
  network_policy = false
}

data "flux_sync" "main" {
  target_path = local.target_path
  url         = "https://github.com/${var.github_slug}"
}

data "kubectl_file_documents" "apply" {
  content = data.flux_install.main.content
}

data "kubectl_file_documents" "sync" {
  content = data.flux_sync.main.content
}

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

resource "kubectl_manifest" "apply" {
  for_each   = { for v in local.apply : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubectl_manifest" "sync" {
  for_each   = { for v in local.sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubernetes_secret" "main" {
  depends_on = [kubectl_manifest.apply]

  metadata {
    name      = data.flux_sync.main.secret
    namespace = data.flux_sync.main.namespace
  }

  data = {
    username = "git"
    password = var.flux_github_token
  }
}
