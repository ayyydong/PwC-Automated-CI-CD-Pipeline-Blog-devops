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
  project = "elemental-shine-376200"
  alias = "devops"
}