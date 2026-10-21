variable "control_project_id" {
  description = "GCP project that hosts Cloud Build connection, triggers, and SAs"
  type        = string
}

variable "region" {
  description = "Default region for Cloud Build resources"
  type        = string
  default     = "asia-northeast1"
}

variable "github_owner" {
  description = "GitHub org or user that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "gcp-cloudbuild-advanced"
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID for Cloud Build"
  type        = number
}

variable "github_oauth_secret_id" {
  description = "Secret Manager secret ID that stores the GitHub App OAuth token"
  type        = string
  default     = "github-oauth-token"
}

variable "tfstate_bucket" {
  description = "GCS bucket used as Terraform remote state"
  type        = string
}

variable "enabled_envs" {
  description = "Environments to provision (progressive rollout). Example: [\"dev\"] then [\"dev\", \"prd\"]"
  type        = list(string)
  default     = []
}
