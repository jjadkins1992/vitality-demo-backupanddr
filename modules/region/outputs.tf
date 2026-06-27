output "subnet_id" {
  value = google_compute_subnetwork.backup_subnet.id
}
output "subnet_cidr" {
  value = google_compute_subnetwork.backup_subnet.ip_cidr_range
}
