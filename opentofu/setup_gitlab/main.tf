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

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-kind"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


locals {
  env = { for tuple in regexall("(.*)=(.*)", file("../../.env")) : tuple[0] => tuple[1] }
}

variable "gitlab_runner_token" {
  description = "GitLab Runner Registration Token"
  type        = string
  sensitive   = true
  default     = ""
}

data "external" "hostname" {
  program = ["sh", "-c", "echo '{\"hostname\": \"'$(hostname)'\"}'"]
}

data "kubernetes_service" "kubernetes" {
  metadata {
    name      = "kubernetes"
    namespace = "default"
  }
}

locals {
  hostname = chomp(data.external.hostname.result.hostname)
  gitlab_url = "https://gitlab.${local.hostname}"
}

locals {
  cluster_ip = data.kubernetes_service.kubernetes.spec[0].cluster_ip
}

module "gitlab_setup" {
  source     = "./modules/gitlab_setup"
  hostname   = local.hostname
  gitlab_url = local.gitlab_url
  cluster_ip = local.cluster_ip
  pg_password = coalesce(local.env["PG_PASSWORD"], "")
  runner_token =  coalesce(local.env["GITLAB_RUNNER_TOKEN"], "")
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}


output "your_gitlab_url" {
  value = module.gitlab_setup.final_gitlab_url
  description = "Deine GitLab URL"
  sensitive = false
}

output "your_gitlab_admin_username" {
  value = module.gitlab_setup.gitlab_root_username
  description = "Dein GitLab Benutzername"
  sensitive = false
}

output "your_gitlab_inital_password" {
  value = "findest du im kubernetes secret gitlab-gitlab-inital-root-password"
  sensitive = false
  description = "Dein Passwort"
}