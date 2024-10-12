variable "gitlab_url" {}

variable "hostname" {
  description = "The hostname of the runner"
  type        = string
}

variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
}

variable "gitlab_token" {
  description = "GitLab Personal Access Token"
  type        = string
  sensitive   = true
}