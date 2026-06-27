resource "google_backup_dr_management_server" "management_server" {
  project  = var.management_project_id
  location = var.region
  name     = "backup-dr-management-server"
  type     = "BACKUP_RESTORE"
  networks {
    network      = var.vpc_id
    peering_mode = "PRIVATE_SERVICE_ACCESS"
  }
  depends_on = [var.private_service_connection]
  lifecycle {
    ignore_changes = all
  }
}

resource "time_sleep" "wait_for_management_server" {
  create_duration = "600s"
  depends_on      = [google_backup_dr_management_server.management_server]
}
