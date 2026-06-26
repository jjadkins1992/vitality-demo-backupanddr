terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.management_project_id
  region  = var.region
  zone    = var.zone
}

module "management" {
  source                     = "../../modules/management"
  management_project_id      = var.management_project_id
  region                     = var.region
  zone                       = var.zone
  subnet_cidr                = var.subnet_cidr
}

module "vault_compute_nonprod" {
  source         = "../../modules/vault"
  project_id     = var.management_project_id
  vault_name     = "vault-us-central1-compute-nonprod"
  location       = var.region
  description    = "Non-prod vault for Compute Engine and Persistent Disks"
  retention_days = var.nonprod_retention_days
  environment    = "nonprod"
  tier           = "compute"
}

module "vault_database_nonprod" {
  source         = "../../modules/vault"
  project_id     = var.management_project_id
  vault_name     = "vault-us-central1-database-nonprod"
  location       = var.region
  description    = "Non-prod vault for Cloud SQL and AlloyDB"
  retention_days = var.nonprod_retention_days
  environment    = "nonprod"
  tier           = "database"
}
