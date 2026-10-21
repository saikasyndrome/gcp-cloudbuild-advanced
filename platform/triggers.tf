resource "google_cloudbuild_trigger" "plan" {
  for_each = toset(local.project_paths)

  project     = var.control_project_id
  location    = var.region
  name        = "${replace(each.value, "/", "-")}-plan"
  description = "PR plan for ${each.value}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.this.id
    pull_request {
      branch = ".*"
    }
  }

  included_files = ["envs/${each.value}/**"]
  filename       = "cloudbuild/plan.yaml"

  service_account = google_service_account.executor[split("/", each.value)[0]].id

  substitutions = {
    _PROJECT_DIR = "envs/${each.value}"
    _TF_SA       = google_service_account.terraform[split("/", each.value)[0]].email
    _OWNER       = var.github_owner
    _REPO        = var.github_repo
    _TFCMT_VER   = "v4.14.15"
  }

  depends_on = [
    google_cloudbuildv2_repository.this,
    google_service_account_iam_member.executor_impersonates,
    google_service_account_iam_member.cloudbuild_actas_executor,
  ]
}

resource "google_cloudbuild_trigger" "apply" {
  for_each = toset(local.project_paths)

  project     = var.control_project_id
  location    = var.region
  name        = "${replace(each.value, "/", "-")}-apply"
  description = "Tag apply for ${each.value}"

  repository_event_config {
    repository = google_cloudbuildv2_repository.this.id
    push {
      tag = "^${split("/", each.value)[1]}_.*"
    }
  }

  filename = "cloudbuild/apply.yaml"

  approval_config {
    approval_required = true
  }

  service_account = google_service_account.executor[split("/", each.value)[0]].id

  substitutions = {
    _PROJECT_DIR = "envs/${each.value}"
    _TF_SA       = google_service_account.terraform[split("/", each.value)[0]].email
  }

  depends_on = [
    google_cloudbuildv2_repository.this,
    google_service_account_iam_member.executor_impersonates,
    google_service_account_iam_member.cloudbuild_actas_executor,
  ]
}
