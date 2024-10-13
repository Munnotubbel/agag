variable "namespace" {
  description = "The Kubernetes namespace to install the GitLab Runner"
  type        = string
  default     = "gitlab-runner"
}

variable "chart_version" {
  description = "The version of the GitLab Runner Helm chart to use"
  type        = string
  default     = "0.69"
}


variable "gitlab_token" {
  description = "GitLab Personal Access Token"
  type        = string
  sensitive   = true
}

variable "runner_token" {
  description = "GitLab Runner Registration Token"
  type        = string
  sensitive   = true
}


variable "concurrent_runners" {
  description = "The number of concurrent runners"
  type        = number
  default     = 20
}

variable "additional_helm_values" {
  description = "Additional Helm values to set on the GitLab Runner chart"
  type        = map(string)
  default     = {}
}

variable "gitlab_url" {
  description = "The URL of the GitLab instance"
  type        = string
}

variable "hostname" {
  description = "The hostname of the runner"
  type        = string


}