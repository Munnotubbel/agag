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

  resource "kubernetes_secret" "gitlab_runner_tls" {
    metadata {
      name      = "gitlab-runner-tls"
      # namespace = kubernetes_namespace.gitlab_runner.metadata[0].name
      namespace = "gitlab-runner"
    }

    data = {
      "gitlab.crt" = data.kubernetes_secret.gitlab_tls.data["tls.crt"]
    }

    type = "Opaque"
  }

  data "kubernetes_secret" "gitlab_tls" {
    metadata {
      name      = "gitlab-gitlab-tls"
      namespace = "gitlab"
    }
  }

data "kubernetes_secret" "gitlab_runner_secret" {
  metadata {
    name      = "gitlab-gitlab-runner-secret"
    namespace = "gitlab"
  }
}

resource "kubernetes_cluster_role_binding" "gitlab_runner_admin" {
  metadata {
    name = "gitlab-runner-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "gitlab-runner"
    namespace = "gitlab-runner"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}

resource "kubernetes_service_account" "gitlab_runner" {
  metadata {
    name      = "gitlab-runner"
    namespace = "gitlab-runner"
  }
}

locals {
  runner_registration_token = data.kubernetes_secret.gitlab_runner_secret.data["runner-registration-token"]
}


  resource "helm_release" "gitlab_runner" {
    name       = "gitlab-runner"
    repository = "https://charts.gitlab.io"
    chart      = "gitlab-runner"
    namespace  = "gitlab-runner"
    version    = var.chart_version
    wait       = false

    set {
      name  = "gitlabUrl"
      # value = "https://gitlab.${var.hostname}"
      value = "http://gitlab-webservice-default.gitlab.svc.cluster.local:8080"
    
    }

    set {
        name  = "runnerRegistrationToken"
        value = local.runner_registration_token
      }

    set {
      name  = "rbac.create"
      value = false
    }

    set {
      name = "rbac.serviceAccountName"
      value = "gitlab-runner"
    }

    set {
      name  = "serviceAccount.create"
      value = false
    }
    
    set {
      name  = "serviceAccount.name"
      value = "gitlab-runner"
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
      value = 15
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
      value = 10
    }
    
    set  {
      name = "connectionMaxAge"
      value = "600m"
    }

    set {
      name  = "certsSecretName"
      value = "gitlab-runner-tls"
    }
    set {
      name  = "runners.config"
      value = <<-EOT
        [[runners]]
          environment = ["GIT_SSL_NO_VERIFY=1"]
          [runners.kubernetes]
          namespace = "gitlab-runner"
          service_account = "gitlab-runner"
          [runners.kubernetes.volumes]
            [[runners.kubernetes.volumes.secret]]
              name = "${kubernetes_secret.gitlab_runner_tls.metadata[0].name}"
              mount_path = "/etc/gitlab-runner/certs/"
          [runners.tls]
            ca_file = "/etc/gitlab-runner/certs/gitlab.crt"
      EOT
    }

    dynamic "set" {
      for_each = var.additional_helm_values
      content {
        name  = set.key
        value = set.value
      }
    }
  }



    # set {
    #   name  = "rbac.rules[0].verbs"
    #   value = "{get,list,watch,create,patch,update,delete}"
    # }

    # set {
    #   name  = "rbac.rules[1].apiGroups"
    #   value = "{\"\"}"
    # }

    # set {
    #   name  = "rbac.rules[1].resources"
    #   value = "{pods/exec}"
    # }

    # set {
    #   name  = "rbac.rules[1].verbs"
    #   value = "{create,patch,delete}"
    # }

    # set {
    #   name  = "clusterWideAccess"
    #   value = true
    # }