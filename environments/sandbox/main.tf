terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "google" {
  project = var.management_project_id
  region  = var.region
  zone    = var.zone
}

locals {
  regions = {
    us = {
      name_suffix = "us"
      region      = "us-central1"
      zone        = "us-central1-a"
      cidr        = "10.232.242.0/24"
    }
    eu = {
      name_suffix = "eu"
      region      = "europe-west3"
      zone        = "europe-west3-a"
      cidr        = "10.230.242.0/24"
    }
    asia = {
      name_suffix = "asia"
      region      = "asia-northeast1"
      zone        = "asia-northeast1-a"
      cidr        = "10.234.242.0/24"
    }
  }

  vaults = {
    us-compute-nonprod    = { region = "us-central1",     tier = "compute",  environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Compute Engine and Persistent Disks" }
    us-database-nonprod   = { region = "us-central1",     tier = "database", environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Cloud SQL and AlloyDB" }
    us-compute-prod       = { region = "us-central1",     tier = "compute",  environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Compute Engine and Persistent Disks" }
    us-database-prod      = { region = "us-central1",     tier = "database", environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Cloud SQL and AlloyDB" }
    eu-compute-nonprod    = { region = "europe-west3",    tier = "compute",  environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Compute Engine and Persistent Disks" }
    eu-database-nonprod   = { region = "europe-west3",    tier = "database", environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Cloud SQL and AlloyDB" }
    eu-compute-prod       = { region = "europe-west3",    tier = "compute",  environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Compute Engine and Persistent Disks" }
    eu-database-prod      = { region = "europe-west3",    tier = "database", environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Cloud SQL and AlloyDB" }
    asia-compute-nonprod  = { region = "asia-northeast1", tier = "compute",  environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Compute Engine and Persistent Disks" }
    asia-database-nonprod = { region = "asia-northeast1", tier = "database", environment = "nonprod", retention = var.nonprod_retention_days, description = "Non-prod vault for Cloud SQL and AlloyDB" }
    asia-compute-prod     = { region = "asia-northeast1", tier = "compute",  environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Compute Engine and Persistent Disks" }
    asia-database-prod    = { region = "asia-northeast1", tier = "database", environment = "prod",    retention = var.prod_retention_days,    description = "Prod vault for Cloud SQL and AlloyDB" }
  }
}

module "network" {
  source                = "../../modules/network"
  management_project_id = var.management_project_id
}

module "management" {
  source                     = "../../modules/management"
  management_project_id       = var.management_project_id
  region                     = var.region
  vpc_id                     = module.network.vpc_id
  private_service_connection = module.network.private_service_connection
}

module "region" {
  source                = "../../modules/region"
  for_each              = local.regions
  management_project_id = var.management_project_id
  name_suffix           = each.value.name_suffix
  region                = each.value.region
  zone                  = each.value.zone
  subnet_cidr           = each.value.cidr
  vpc_id                = module.network.vpc_id
  vpc_name              = module.network.vpc_name
  management_server_api = module.management.management_server_api

  depends_on = [module.management]
}

module "vault" {
  source         = "../../modules/vault"
  for_each       = local.vaults
  project_id     = var.management_project_id
  vault_name     = "vault-${each.value.region}-${each.value.tier}-${each.value.environment}"
  location       = each.value.region
  description    = each.value.description
  retention_days = each.value.retention
  environment    = each.value.environment
  tier           = each.value.tier
}
