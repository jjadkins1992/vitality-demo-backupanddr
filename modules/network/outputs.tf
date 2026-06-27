output "vpc_id" {
  value = google_compute_network.backup_vpc.id
}
output "vpc_name" {
  value = google_compute_network.backup_vpc.name
}
output "private_service_connection" {
  value = google_service_networking_connection.private_service_connection.id
}
