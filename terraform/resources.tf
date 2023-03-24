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

resource "google_storage_bucket" "bucket" {
  provider = google.devops
  name     = "tf-slack-bucket"
  location = "US"
}

resource "google_storage_bucket_object" "archive" {
  provider = google.devops
  name     = "subscribe.zip"
  bucket   = google_storage_bucket.bucket.name
  source   = "slack-notifier.zip"
}

# https://stackoverflow.com/questions/65444187/trigger-topic-not-working-on-terraform-resource-google-cloudfunctions-function
# resource "google_cloudfunctions_function" "subscribe" {
#   provider    = google.devops
#   name        = "subscribe"
#   description = "Slack notifier deployed using tf"
#   runtime     = "nodejs18"
#   region      = "us-west2"

#   available_memory_mb   = 128
#   source_archive_bucket = google_storage_bucket.bucket.name
#   source_archive_object = google_storage_bucket_object.archive.name
#   entry_point           = "subscribe"

#   event_trigger {
#     event_type = "google.pubsub.topic.publish"
#     resource   = "cloud-builds" # "projects/elemental-shine-376200/topics/cloud-builds-topic" 
#   }
# }

# resource "google_cloudfunctions2_function" "subscribe" {
#   provider    = google.devops
#   name        = "subscribe"
#   location    = "us-west2"
#   description = "Slack notifier deployed using tf"

#   build_config {
#     runtime     = "nodejs18"
#     entry_point = "subscribe" 

#     source {
#       storage_source {
#         bucket = google_storage_bucket.bucket.name
#         object = google_storage_bucket_object.archive.name
#       }
#     }
#   }

#   event_trigger {
#     trigger_region = "us-west2"
#     event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
#     pubsub_topic   = "projects/elemental-shine-376200/topics/cloud-builds"
#     retry_policy   = "RETRY_POLICY_RETRY"
#   }
# }