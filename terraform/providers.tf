terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("./gcp_keys/devops_tf_key.json")
  project     = var.devops_project_id
  alias       = "devops"
}