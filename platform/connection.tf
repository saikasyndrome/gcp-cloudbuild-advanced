resource "google_cloudbuildv2_connection" "github" {
  project  = var.control_project_id
  location = var.region
  name     = "github-connection"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = data.google_secret_manager_secret_version.github_oauth.id
    }
  }
}

resource "google_cloudbuildv2_repository" "this" {
  project           = var.control_project_id
  location          = var.region
  name              = var.github_repo
  parent_connection = google_cloudbuildv2_connection.github.name
  remote_uri        = local.github_remote_uri
}
