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
  config_context = "kind-kind"
}

provider "gitlab" {
  token    = var.gitlab_token
  base_url = local.gitlab_url
  insecure = true
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

locals {
  ssh_public_key = file("~/.ssh/id_rsa.pub")
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

locals {
  hostname = chomp(data.external.hostname.result.hostname)
  gitlab_url = "http://gitlab.${local.hostname}"
}

module "gitlab_structure" {
  source = "./modules/gitlab_structure"
  gitlab_url = local.gitlab_url
  hostname = local.hostname
  ssh_public_key = local.ssh_public_key
  gitlab_token   = var.gitlab_token
  providers = {
    kubernetes = kubernetes
    gitlab = gitlab
  }
}


module "kubernetes" {
  source              = "./modules/kubernetes"
  gitlab_deploy_token = module.gitlab_structure.deploy_token
  gitlab_agent_token  = module.gitlab_structure.gitlab_agent_token
  gitlab_url          = local.gitlab_url
  hostname = local.hostname
  ssh_public_key = local.ssh_public_key
  gitlab_token   = var.gitlab_token
  providers = {
    kubernetes = kubernetes
    helm = helm
  }
}

module "gitlab_runners" {
  source = "./modules/gitlab_runners"
  hostname = local.hostname
  namespace                 = "gitlab-runner"
  gitlab_url = local.gitlab_url
  gitlab_token   = var.gitlab_token
  runner_token =  coalesce(local.env["GITLAB_RUNNER_TOKEN"], "")
  providers = {
    kubernetes = kubernetes
    helm = helm
    gitlab = gitlab
  }
}




output "gitlab_projects" {
  value     = module.gitlab_structure.gitlab_projects
  sensitive = false
}

output "kubernetes_namespaces" {
  value = module.kubernetes.kubernetes_namespaces
}
