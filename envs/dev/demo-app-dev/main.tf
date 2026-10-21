variable "project_id" {
  type    = string
  default = "demo-app-dev"
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Minimal sample resource so plan/apply have something to manage
resource "google_storage_bucket" "demo" {
  name                        = "${var.project_id}-demo-artifacts"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  labels = {
    env     = "dev"
    managed = "gcp-cloudbuild-advanced"
  }
}
