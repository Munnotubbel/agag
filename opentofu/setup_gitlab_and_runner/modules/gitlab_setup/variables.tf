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


