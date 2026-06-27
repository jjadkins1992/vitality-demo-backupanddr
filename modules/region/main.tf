resource "google_compute_subnetwork" "backup_subnet" {
  project                  = var.management_project_id
  name                     = "backup-dr-subnet-${var.name_suffix}"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = var.vpc_id
  private_ip_google_access = true
}

resource "google_compute_router" "backup_router" {
  project = var.management_project_id
  name    = "backup-dr-router-${var.name_suffix}"
  region  = var.region
  network = var.vpc_id
}

resource "google_compute_router_nat" "backup_nat" {
  project                            = var.management_project_id
  name                               = "backup-dr-nat-${var.name_suffix}"
  router                             = google_compute_router.backup_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

module "backup_dr_appliance" {
  source  = "GoogleCloudPlatform/backup-dr/google"
  version = "0.6.0"

  ba_project_id              = var.management_project_id
  region                     = var.region
  zone                       = var.zone
  vpc_host_project_id        = var.management_project_id
  network                    = var.vpc_name
  subnet                     = google_compute_subnetwork.backup_subnet.name
  ms_project_id              = var.management_project_id
  management_server_endpoint = var.management_server_api
  ba_name                    = "bkp-dr-${var.name_suffix}"
  create_ba_service_account  = true
  assign_roles_to_ba_sa      = true
  ba_appliance_type          = "STANDARD_FOR_COMPUTE_ENGINE_VMS"
  ba_registration            = true

  depends_on = [
    google_compute_subnetwork.backup_subnet,
    google_compute_router_nat.backup_nat
  ]
}
