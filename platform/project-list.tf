locals {
  # ---------------------------------------------------------------------------
  # Workload catalog (demo values — replace with your own project IDs)
  # Path format: "<env>/<gcp-project-id>"
  # Must match directories under repo root: envs/<env>/<gcp-project-id>/
  # ---------------------------------------------------------------------------
  project_paths_all = [
    # --- Dev ---
    "dev/demo-app-dev",
    # "dev/demo-data-dev",

    # --- Prd ---
    "prd/demo-app-prd",
    # "prd/demo-data-prd",
  ]

  # Per-env CI/CD SA naming (SAs live in the control project)
  cicd_envs = {
    dev = {
      executor_account_id  = "tf-executor-dev"
      executor_display     = "Terraform Executor SA - Dev"
      terraform_account_id = "tf-sa-dev"
      terraform_display    = "Terraform SA - Dev"
    }
    prd = {
      executor_account_id  = "tf-executor-prd"
      executor_display     = "Terraform Executor SA - Prd"
      terraform_account_id = "tf-sa-prd"
      terraform_display    = "Terraform SA - Prd"
    }
  }
}
