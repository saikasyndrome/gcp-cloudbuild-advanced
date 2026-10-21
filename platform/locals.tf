locals {
  # Environments actually provisioned (from var.enabled_envs)
  active_cicd_envs = {
    for env, cfg in local.cicd_envs : env => cfg
    if contains(var.enabled_envs, env)
  }

  # Only paths whose env is enabled
  # Example: "dev/demo-app-dev"
  project_paths = [
    for path in local.project_paths_all : path
    if contains(var.enabled_envs, split("/", path)[0])
  ]

  github_remote_uri = "https://github.com/${var.github_owner}/${var.github_repo}.git"
}
