terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "~> 2.15.0"
    }
  }
}

variable "gitlab_deploy_token" {
  description = "GitLab Deploy Token"
  type        = string
  sensitive   = true
}

variable "gitlab_agent_token" {
  description = "GitLab Agent Token"
  type        = string
  sensitive   = true
}


resource "kubernetes_namespace" "environments" {
  for_each = toset(["dev", "stg", "prod", "monitoring", "gitlab-agent"])

  metadata {
    name = each.key
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "kubernetes_deployment" "uptime_kuma" {
  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.environments["monitoring"].metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "uptime-kuma"
      }
    }

    template {
      metadata {
        labels = {
          app = "uptime-kuma"
        }
      }

      spec {
        container {
          image = "louislam/uptime-kuma:1"
          name  = "uptime-kuma"

          port {
            container_port = 3001
          }

          volume_mount {
            name       = "data"
            mount_path = "/app/data"
          }
        }

        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "uptime_kuma" {
  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.environments["monitoring"].metadata[0].name
  }

  spec {
    selector = {
      app = "uptime-kuma"
    }

    port {
      port        = 80
      target_port = 3001
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "uptime_kuma" {
  metadata {
    name      = "uptime-kuma"
    namespace = kubernetes_namespace.environments["monitoring"].metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "uptime-kuma.localhost"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.uptime_kuma.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}


output "kubernetes_namespaces" {
  value = [for ns in kubernetes_namespace.environments : ns.metadata[0].name]
}

output "uptime_kuma_url" {
  value = "http://${kubernetes_ingress_v1.uptime_kuma.spec[0].rule[0].host}"
}