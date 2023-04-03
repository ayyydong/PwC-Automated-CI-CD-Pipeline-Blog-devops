resource "google_service_account" "cf_account" {
  provider     = google.devops
  account_id   = "cloud-functions-invoker"
  display_name = "Cloudrun service account for invoking cloud functions"
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

resource "google_storage_bucket_object" "deployment_reader_archive" {
  provider = google.devops
  name     = "latest-deployment-reader.zip"
  bucket   = google_storage_bucket.bucket.name
  source   = "latest-deployment-reader.zip"
}

resource "google_cloudfunctions_function" "readDeployment" {
  provider      = google.devops
  name          = "readDeployment"
  description   = "Latest Deployment Reader deployed using tf"
  runtime       = "nodejs18"
  region        = "us-west2"
  max_instances = 50

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.deployment_reader_archive.name
  entry_point           = "readDeployment"

  trigger_http = true
}

resource "google_cloudfunctions_function_iam_binding" "invoker" {
  provider       = google.devops
  project        = google_cloudfunctions_function.readDeployment.project
  region         = google_cloudfunctions_function.readDeployment.region
  cloud_function = google_cloudfunctions_function.readDeployment.name
  role           = "roles/cloudfunctions.invoker"
  members        = ["allUsers"]
  # members = [google_service_account.cf_account.member] # Running into issues with React, could not verify
}

resource "google_cloudbuild_trigger" "tf-non-feature-trigger" {
  provider = google.devops
  location = "us-west2"
  name     = "tf-non-feature"
  filename = "non_feature_cloudbuild.yaml"

  github {
    owner = "CPSC319-2022"
    name  = "9ds-devops"
    push {
      branch       = "^non_feature_pipeline_test$"
      invert_regex = false
    }
  }

  substitutions = {
    _REACT_APP_ENV   = "TERRAFORM"
    _CF_URL          = google_cloudfunctions_function.readDeployment.https_trigger_url
    _SERVICE_ACCOUNT = google_service_account.cf_account.email # could not get IAM
  }

  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
}

resource "google_cloudbuild_trigger" "tf-feature-trigger" {
  provider = google.devops
  location = "us-west2"
  name     = "tf-feature"
  filename = "feature_cloudbuild.yaml"

  github {
    owner = "CPSC319-2022"
    name  = "9ds-devops"
    push {
      branch       = "^(main|non_feature_pipeline_test)$"
      invert_regex = true
    }
  }
  include_build_logs = "INCLUDE_BUILD_LOGS_WITH_STATUS"
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

resource "google_storage_bucket_object" "deploymennt_logger_archive" {
  provider = google.devops
  name     = "latest-deployment-logger.zip"
  bucket   = google_storage_bucket.bucket.name
  source   = "latest-deployment-logger.zip"
}

resource "google_cloudfunctions_function" "logDeployment" {
  provider      = google.devops
  name          = "logDeployment"
  description   = "Latest Deployment Logger deployed using tf"
  runtime       = "nodejs18"
  region        = "us-west2"
  max_instances = 50

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.deploymennt_logger_archive.name
  entry_point           = "logDeployment"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.devops_project_id}/topics/cloud-builds"
  }

  environment_variables = {
    TRIGGER_ID = google_cloudbuild_trigger.tf-non-feature-trigger.trigger_id
  }
}
