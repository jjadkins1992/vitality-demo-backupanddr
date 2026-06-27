output "management_server_id" {
  value = google_backup_dr_management_server.management_server.id
}
output "management_server_uri" {
  value = google_backup_dr_management_server.management_server.management_uri
}
output "management_server_api" {
  value = google_backup_dr_management_server.management_server.management_uri[0].api
}
output "wait_for_management_server" {
  value = time_sleep.wait_for_management_server.id
}
