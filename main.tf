# Enable required APIs for Cloud Run and Firestore
resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

# Service account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "sactcr-${var.name}"
  display_name = "serviceauthcentral Cloud Run (${var.name}) service account"
}

# IAM role to grant Firestore write permissions to Cloud Run service account
resource "google_project_iam_member" "firestore_viewer_role" {
  project = var.project_id
  role    = "roles/datastore.viewer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Deploy Cloud Run services in specified regions
resource "google_cloud_run_v2_service" "serviceauthcentral-token" {
  for_each = toset(var.regions)
  project  = var.project_id
  location = each.value
  name     = "${var.name}-token-${each.value}"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      # TODO: This is hard coded to pull in the dev image from GitHub, this should pull in a released version
      image = "us-docker.pkg.dev/${var.project_id}/ghcr/unitvectory-labs/serviceauthcentral-token:dev"

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "datamodel-firestore,sign-gcp,verify-auth0"
      }
      env {
        name  = "SAC_ISSUER"
        value = var.sac_issuer
      }
      env {
        name  = "SAC_CORS_ORIGINS"
        value = var.sac_cors_origins
      }
      env {
        name  = "SAC_USER_REDIRECTURI"
        value = var.sac_user_redirecturi
      }
      env {
        name  = "SAC_SIGN_GCP_KEY_RING"
        value = var.key_ring_name
      }
      env {
        name  = "SAC_SIGN_GCP_KEY_NAME"
        value = var.sign_key_name
      }
      env {
        name  = "SAC_USER_PROVIDER_GITHUB_CLIENTID"
        value = var.sac_user_provider_github_clientid
      }
      env {
        name  = "SAC_USER_PROVIDER_GITHUB_CLIENTSECRET"
        value = var.sac_user_provider_github_clientsecret
      }
    }
  }
}
