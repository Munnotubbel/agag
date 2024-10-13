variable "hostname" {
  description = "The hostname of the runner"
  type        = string
}

variable "cluster_ip" {
  description = "Password User for the Gitlab PSQL DB"
  type        = string
}

variable "gitlab_url" {
  description = "The URL of the GitLab instance"
  type        = string
}

variable "pg_password" {
  description = "Password for the Gitlab PSQL DB"
  type        = string
}

variable "chart_version" {
  description = "The version of the GitLab Helm chart to use"
  type        = string
  default     = "8.4.2"
}

variable "runner_token" {
  description = "GitLab Runner Registration Token"
  type        = string
  sensitive   = true
}
