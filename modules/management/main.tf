resource "google_compute_network" "backup_vpc" {
  project                 = var.management_project_id
  name                    = "backup-dr-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "backup_subnet" {
  project                  = var.management_project_id
  name                     = "backup-dr-subnet"
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.backup_vpc.id
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_service_range" {
  project       = var.management_project_id
  name          = "backup-dr-private-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.backup_vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.backup_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}

resource "google_backup_dr_management_server" "management_server" {
  project  = var.management_project_id
  location = var.region
  name     = "backup-dr-management-server"
  type     = "BACKUP_RESTORE"
  networks {
    network      = google_compute_network.backup_vpc.id
    peering_mode = "PRIVATE_SERVICE_ACCESS"
  }
  depends_on = [google_service_networking_connection.private_service_connection]

  lifecycle {
    ignore_changes = all
  }
}

resource "time_sleep" "wait_for_management_server" {
  create_duration = "600s"
  depends_on      = [google_backup_dr_management_server.management_server]
}
