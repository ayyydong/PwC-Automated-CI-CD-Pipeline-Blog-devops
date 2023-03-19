resource "google_cloudbuild_trigger" "test-terraform-trigger" {
  provider = google.devops
  location = "us-west2"
  name     = "test-terraform-trigger"
  filename = "non_feature_cloudbuild.yaml"

  github {
    owner = "CPSC319-2022"
    name  = "9ds-devops"
    push {
      branch = "^terraform-test$"
      invert_regex = false
    }
  }

  substitutions = {
      _REACT_APP_ENV = "TERRAFORM"
    }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}
