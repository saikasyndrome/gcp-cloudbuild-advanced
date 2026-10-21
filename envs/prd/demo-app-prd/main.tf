variable "project_id" {
  type    = string
  default = "demo-app-prd"
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "demo" {
  name                        = "${var.project_id}-demo-artifacts"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  labels = {
    env     = "prd"
    managed = "gcp-cloudbuild-advanced"
  }
}
