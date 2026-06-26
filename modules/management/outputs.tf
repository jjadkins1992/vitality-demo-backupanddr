output "management_server_id" {
  description = "The ID of the Backup DR management server"
  value       = google_backup_dr_management_server.management_server.id
}

output "management_server_uri" {
  description = "The URI of the Backup DR management server console"
  value       = google_backup_dr_management_server.management_server.management_uri
}

output "management_server_networks" {
  description = "Network configuration of the management server"
  value       = google_backup_dr_management_server.management_server.networks
}

output "vpc_id" {
  description = "The ID of the backup VPC"
  value       = google_compute_network.backup_vpc.id
}

output "subnet_id" {
  description = "The ID of the backup subnet"
  value       = google_compute_subnetwork.backup_subnet.id
}
