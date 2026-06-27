resource "google_compute_network" "backup_vpc" {
  project                 = var.management_project_id
  name                    = "backup-dr-vpc"
  auto_create_subnetworks = false
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
