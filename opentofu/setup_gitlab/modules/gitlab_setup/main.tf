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
  }
}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}


resource "kubernetes_secret" "gitlab_postgresql_password" {
  metadata {
    name      = "gitlab-psql-pw"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }
  data = {
    postgresql-postgres-password = var.pg_password
  }
}

resource "kubernetes_secret" "gitlab_runner" {
  metadata {
    name      = "gitlab-runner"
    namespace = "gitlab"
  }

  data = {
    registrationToken = base64encode(var.runner_token)
  }

  type = "Opaque"
}

resource "helm_release" "gitlab" {
  depends_on = [kubernetes_secret.gitlab_postgresql_password]
  name       = "gitlab"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  namespace  = kubernetes_namespace.gitlab.metadata[0].name
  version    = var.chart_version
  wait = false

   set {
    name  = "global.edition"
    value = "ce"
  }

    set {
    name = "gitlab.webservice.replicaCount"
    value = 1
  }

  set {
    name = "gitlab.gitlab-shell.replicaCount"
    value = 1
  }

  set {
    name  = "global.hosts.externalIP"
    value = var.cluster_ip
  }

  set {
    name = "global.shell.port"
    value = 30103
  }

  set {
    name  = "global.hosts.domain"
    value = var.hostname
  }

  set {
    name  = "global.kas.enabled"
    value = false
  }

  set {
    name = "gitlab.gitlab-shell.service.type"
    value = "NodePort"
  }

  set {
    name = "gitlab.gitlab-shell.service.nodePort"
    value = 30103
  }


  set {
    name  = "certmanager-issuer.email"
    value = "admin@from-hell.gg"
  }

  set {
    name  = "postgresql.install"
    value = "true"
  }

  set {
    name  = "global.psql.host"
    value = "gitlab-postgresql"
  }

  set {
    name  = "global.psql.port"
    value = "5432"
  }

  set {
    name  = "global.psql.password.secret"
    value = "gitlab-psql-pw"
  }

  set {
    name  = "global.psql.password.key"
    value = "postgresql-postgres-password"
  }

  set {
    name  = "redis.storageClass"
    value = "local-storage"
  }

  set {
    name  = "gitlab.gitaly.persistance.size"
    value = "30Gi"
  }

  set {
    name  = "gitlab.gitaly.persistance.storageClass"
    value = "local-storage"
  }

  set {
    name  = "prometheus.server.persistantVolume.size"
    value = "10Gi"
  }

  set {
    name  = "prometheuss.server.persistantVolume.storageClass"
    value = "local-storage"
  }

  set {
    name  = "minio.persistance.size"
    value = "10Gi"
  }

   set {
    name  = "minio.persistance.storageClass"
    value = "local-storage"
  }

  set {
    name  = "gitlab-runner.install"
    value = false
  }

  set {
    name  = "gitlab.toolbox.backups.cron.enabled"
    value = true
  }


}


output "final_gitlab_url" {
  value = "http://gitlab.${var.hostname}"  # Oder wie auch immer Ihre GitLab-URL definiert ist
  description = "Deine Gitlab URL"
  sensitive = false
}

output "gitlab_root_username" {
  value = "root"
  sensitive = false
  description = "Dein Gitlab Username"
}
