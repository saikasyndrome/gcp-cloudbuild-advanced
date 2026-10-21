data "google_project" "control" {
  project_id = var.control_project_id
}

data "google_secret_manager_secret_version" "github_oauth" {
  project = var.control_project_id
  secret  = var.github_oauth_secret_id
  version = "latest"
}
