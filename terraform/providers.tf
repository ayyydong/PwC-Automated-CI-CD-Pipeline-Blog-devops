terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("./gcp_keys/9ds_devops_terraform_key.json")
  project     = var.devops_project_id
  alias       = "devops"
}