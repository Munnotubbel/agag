terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "~> 2.0"
    }
    gitlab = {
      source  = "opentofu/gitlab"
      version = "~> 17.4.0"
    }
  }
}

# --- for future authentication_flow after deprecation of the RegistrationToken ---
resource "gitlab_user_runner" "gitlab_runner" {
  description = "Kubernetes GitLab Runner"
  untagged = true
  locked = false
  access_level = "ref_protected"
  runner_type = "instance_type"
}

resource "kubernetes_namespace" "gitlab_runner" {
  metadata {
    name = var.namespace
  }
}
resource "helm_release" "gitlab_runner" {
  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  namespace  = kubernetes_namespace.gitlab_runner.metadata[0].name
  version    = var.chart_version
  wait       = false

  set {
    name  = "gitlabUrl"
    value = "https://gitlab.${var.hostname}"
  }

  set {
      name  = "runnerRegistrationToken"
      value = var.runner_token
    }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "rbac.rules[0].verbs"
    value = "{get,list,watch,create,patch,update,delete}"
  }

  set {
    name  = "rbac.rules[1].apiGroups"
    value = "{\"\"}"
  }

  set {
    name  = "rbac.rules[1].resources"
    value = "{pods/exec}"
  }

  set {
    name  = "rbac.rules[1].verbs"
    value = "{create,patch,delete}"
  }

  set {
    name  = "clusterWideAccess"
    value = true
  }

  set {
    name  = "runners.privileged"
    value = true
  }

  set {
    name  = "runners.namespace"
    value = kubernetes_namespace.gitlab_runner.metadata[0].name
  }

  set {
    name  = "concurrent"
    value = var.concurrent_runners
  }

  set {
    name  = "checkInterval"
    value = 30
  }

  set {
    name  = "runners.image"
    value = "alpine:latest"
  }

  set {
    name  = "runners.tags"
    value = "shared"
  }

  set {
    name  = "runners.runUntagged"
    value = true
  }

  set {
    name  = "runners.executor"
    value = "kubernetes"
  }

  set {
    name ="shutdown_timeout"
    value = 3
  }

  # set {
  #   name  = "certsSecretName"
  #   value = "gitlab-runner-certs"
  # }

  # set {
  #   name  = "runners.config"
  #   value = <<-EOT
  #     [[runners]]
  #       [runners.kubernetes]
  #       [runners.kubernetes.volumes]
  #         [[runners.kubernetes.volumes.secret]]
  #           name = "gitlab-runner-certs"
  #           mount_path = "/etc/gitlab-runner/certs/"
  #   EOT
  # }

  dynamic "set" {
    for_each = var.additional_helm_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

