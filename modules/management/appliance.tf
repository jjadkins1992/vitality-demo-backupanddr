module "backup_dr_appliance" {
  source  = "GoogleCloudPlatform/backup-dr/google"
  version = "0.6.0"

  ba_project_id              = var.management_project_id
  region                     = var.region
  zone                       = var.zone
  vpc_host_project_id        = var.management_project_id
  network                    = google_compute_network.backup_vpc.name
  subnet                     = google_compute_subnetwork.backup_subnet.name
  ms_project_id              = var.management_project_id
  management_server_endpoint = google_backup_dr_management_server.management_server.management_uri[0].web_ui
  ba_name                    = "backup-dr-appliance"
  create_ba_service_account  = true
  assign_roles_to_ba_sa      = true
  ba_appliance_type          = "STANDARD_FOR_COMPUTE_ENGINE_VMS"

  depends_on = [
    time_sleep.wait_for_management_server,
    google_compute_subnetwork.backup_subnet
  ]
}
