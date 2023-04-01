resource "google_cloudbuild_trigger" "test-terraform-trigger" {
  provider = google.devops
  location = "us-west2"
  name     = "test-terraform-trigger"
  filename = "non_feature_cloudbuild.yaml"

  github {
    owner = "CPSC319-2022"
    name  = "9ds-devops"
    push {
      branch       = "^terraform-test$"
      invert_regex = false
    }
  }

  substitutions = {
    _REACT_APP_ENV = "TERRAFORM"
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

# https://cloud.google.com/functions/docs/tutorials/terraform
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "bucket" {
  provider = google.devops
  name     = "functions-${var.devops_project_id}-${random_id.bucket_suffix.hex}"
  location = "US"
}

resource "google_storage_bucket_object" "archive" {
  provider = google.devops
  name     = "subscribe.zip"
  bucket   = google_storage_bucket.bucket.name
  source   = "slack-notifier.zip"
}

# https://stackoverflow.com/questions/65444187/trigger-topic-not-working-on-terraform-resource-google-cloudfunctions-function
resource "google_cloudfunctions_function" "subscribe" {
  provider      = google.devops
  name          = "subscribe"
  description   = "Slack notifier deployed using tf"
  runtime       = "nodejs18"
  region        = "us-west2"
  max_instances = 50

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point           = "subscribe"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.devops_project_id}/topics/cloud-builds"
  }
}
