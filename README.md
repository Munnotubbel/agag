    kannst du mir den folgenden fehler analysieren den ich aktuell beim apply meiner tofu files bekomme? ich habe es dir i nder paste.txt hochgeladen

    hier ist meine main.tf

    terraform {
    required_providers {
        kubernetes = {
        source  = "opentofu/kubernetes"
        version = "~> 2.0"
        }
        gitlab = {
        source  = "opentofu/gitlab"
        version = "~> 17.4.0"
        }
        helm = {
        source  = "opentofu/helm"
        version = "~> 2.15.0"
        }
    }
    }

    provider "kubernetes" {
    config_path    = "~/.kube/config"
    config_context = "minikube"
    }

    provider "gitlab" {
    token    = var.gitlab_token
    base_url = var.gitlab_url
    }

    provider "helm" {
    kubernetes {
        config_path = "~/.kube/config"
    }
    }

    variable "gitlab_token" {
    description = "GitLab Personal Access Token"
    type        = string
    sensitive   = true
    }

    variable "gitlab_url" {
    description = "GitLab URL"
    type        = string
    default     = "http://gitlab.local"
    }

    variable "ssh_public_key" {
    description = "Your SSH public key"
    type        = string
    }

    module "kubernetes" {
    source              = "./modules/kubernetes"
    gitlab_deploy_token = module.gitlab.deploy_token
    gitlab_agent_token  = module.gitlab.gitlab_agent_token
    gitlab_url          = var.gitlab_url
    }

    module "gitlab" {
    source         = "./modules/gitlab"
    gitlab_token   = var.gitlab_token
    gitlab_url     = var.gitlab_url
    ssh_public_key = var.ssh_public_key
    }

    output "gitlab_projects" {
    value     = module.gitlab.gitlab_projects
    sensitive = false
    }

    output "kubernetes_namespaces" {
    value = module.kubernetes.kubernetes_namespaces
    }

    output "gitlab_deploy_token" {
    value     = module.gitlab.deploy_token
    sensitive = true
    }


    hier ist die main.tf meines gitlab modules

    terraform {
    required_providers {
        gitlab = {
        source  = "opentofu/gitlab"
        version = "~> 17.4.0"
        }
        kubernetes = {
        source  = "opentofu/kubernetes"
        version = "~> 2.0"
        }
    }
    }

    variable "gitlab_token" {
    description = "GitLab Personal Access Token"
    type        = string
    sensitive   = true
    }

    variable "gitlab_url" {
    description = "GitLab URL"
    type        = string
    }

    variable "ssh_public_key" {
    description = "Your SSH public key"
    type        = string
    }

    provider "gitlab" {
    token    = var.gitlab_token
    base_url = var.gitlab_url
    }

    provider "kubernetes" {
    config_path = "~/.kube/config"
    }

    resource "gitlab_group" "ententeich" {
    name             = "Ententeich"
    path             = "ententeich"
    description      = "Gruppe für Ententeich Microservices"
    visibility_level = "public"
    }

    resource "gitlab_project" "microservices" {
    for_each                         = toset(["frontente", "backente", "ci-cd"])
    name                             = each.key
    description                      = "the real ${each.key} repo"
    namespace_id                     = gitlab_group.ententeich.id
    visibility_level                 = "public"
    repository_access_level          = "enabled"
    container_registry_access_level  = "enabled"
    initialize_with_readme           = false
    default_branch                   = "main"
    }

    resource "gitlab_branch_protection" "main" {
    for_each           = gitlab_project.microservices
    project            = each.value.id
    branch             = "main"
    push_access_level  = "developer"
    merge_access_level = "developer"
    }

    resource "gitlab_deploy_token" "ci_cd_token" {
    project    = gitlab_project.microservices["ci-cd"].id
    name       = "CI/CD Deploy Token"
    username   = "gitlab+deploy-token-1"
    expires_at = timeadd(timestamp(), "8760h")

    scopes = [
        "read_registry",
        "write_registry",
        "read_repository",
    ]
    }

    resource "gitlab_project_variable" "ci_cd_token" {
    project   = gitlab_project.microservices["ci-cd"].id
    key       = "CI_CD_TOKEN"
    value     = gitlab_deploy_token.ci_cd_token.token
    protected = false
    masked    = false
    }


    resource "gitlab_project_variable" "ci_server_url" {
    project   = gitlab_project.microservices["ci-cd"].id
    key       = "CI_SERVER_URL"
    value     = var.gitlab_url
    protected = false
    masked    = false
    }

    resource "gitlab_user_sshkey" "user_sshkey" {
    title = "User SSH Key"
    key   = var.ssh_public_key

    lifecycle {
        ignore_changes = [key]
    }
    }

    resource "gitlab_cluster_agent" "k8s_agent" {
    project = gitlab_project.microservices["ci-cd"].id
    name    = "kubernetes-agent"
    }

    resource "gitlab_cluster_agent_token" "k8s_agent_token" {
    project  = gitlab_project.microservices["ci-cd"].id
    agent_id = gitlab_cluster_agent.k8s_agent.agent_id
    name     = "k8s-agent-token"
    }

    resource "gitlab_project_variable" "k8s_agent_token" {
    project   = gitlab_project.microservices["ci-cd"].id
    key       = "K8S_AGENT_TOKEN"
    value     = gitlab_cluster_agent_token.k8s_agent_token.token
    protected = true
    masked    = true
    }

    output "gitlab_projects" {
    value = { for k, v in gitlab_project.microservices : k => v.web_url }
    }

    output "deploy_token" {
    value     = gitlab_deploy_token.ci_cd_token.token
    sensitive = true
    }

    output "gitlab_agent_token" {
    value     = gitlab_cluster_agent_token.k8s_agent_token.token
    sensitive = true
    }


    hier ist das main.tf meines kubernetes modules


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

    variable "gitlab_url" {
    description = "GitLab URL"
    type        = string
    }

    variable "host_os" {
    description = "Host operating system (linux or mac)"
    type        = string
    default     = "linux"
    }

    locals {
    gitlab_host = var.host_os == "mac" ? "host.docker.internal" : var.gitlab_url
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
      host = "uptime-kuma.local"
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

resource "helm_release" "gitlab_agent" {
  name       = "gitlab-agent"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-agent"
  namespace  = kubernetes_namespace.environments["gitlab-agent"].metadata[0].name

  set {
    name  = "config.token"
    value = var.gitlab_agent_token
  }

  set {
    name  = "config.kasAddress"
    value = "ws://192.168.49.1:80/-/kubernetes-agent/"
  }

  set {
    name  = "config.gitlabUrl"
    value = "http://192.168.49.1:80"
  }

  set {
    name  = "config.cas.acceptInsecureCertificates"
    value = "true"
  }
}

output "kubernetes_namespaces" {
  value = [for ns in kubernetes_namespace.environments : ns.metadata[0].name]
}

output "uptime_kuma_url" {
  value = "http://${kubernetes_ingress_v1.uptime_kuma.spec[0].rule[0].host}"
}