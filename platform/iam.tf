# Executor SA — runs Cloud Build steps
resource "google_service_account" "executor" {
  for_each = local.active_cicd_envs

  project      = var.control_project_id
  account_id   = each.value.executor_account_id
  display_name = each.value.executor_display
}

# Terraform SA — impersonated by executor to mutate workload projects
resource "google_service_account" "terraform" {
  for_each = local.active_cicd_envs

  project      = var.control_project_id
  account_id   = each.value.terraform_account_id
  display_name = each.value.terraform_display
}

# Terraform SA can edit each workload project in that env
resource "google_project_iam_member" "terraform_editor" {
  for_each = toset(local.project_paths)

  project = split("/", each.value)[1]
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform[split("/", each.value)[0]].email}"
}

# Executor may impersonate the matching Terraform SA
resource "google_service_account_iam_member" "executor_impersonates" {
  for_each = local.active_cicd_envs

  service_account_id = google_service_account.terraform[each.key].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.executor[each.key].email}"
}

# Cloud Build service agent may ActAs executor SAs
resource "google_service_account_iam_member" "cloudbuild_actas_executor" {
  for_each = local.active_cicd_envs

  service_account_id = google_service_account.executor[each.key].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.control.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Remote state access for Terraform SAs
resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = local.active_cicd_envs

  bucket = var.tfstate_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform[each.key].email}"
}

# Minimal logging for executor SAs
resource "google_project_iam_member" "executor_logs" {
  for_each = local.active_cicd_envs

  project = var.control_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.executor[each.key].email}"
}

# GitHub token for tfcmt (create secret value manually in console)
resource "google_secret_manager_secret" "github_token" {
  count = length(local.active_cicd_envs) > 0 ? 1 : 0

  project   = var.control_project_id
  secret_id = "GITHUB_TOKEN"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_iam_member" "github_token_accessor" {
  for_each = local.active_cicd_envs

  secret_id = google_secret_manager_secret.github_token[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.executor[each.key].email}"
}
