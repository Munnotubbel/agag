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


output "gitlab_hostname" {
  value = "https://gitlab.${coalesce(var.hostname, "http://localhost")}"
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

locals {
  kubeconfig_content = file("~/.kube/config")
}

resource "gitlab_project_variable" "kubeconfig" {
  project     = gitlab_project.microservices["ci-cd"].id
  key         = "KUBECONFIG"
  value       = local.kubeconfig_content
  variable_type = "file"
  protected   = true
  masked      = false
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