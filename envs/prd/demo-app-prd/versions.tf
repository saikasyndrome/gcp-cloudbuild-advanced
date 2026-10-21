terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # backend "gcs" {
  #   bucket = "demo-cicd-control-tfstate"
  #   prefix = "envs/prd/demo-app-prd"
  # }
}
