output "management_server_id" {
  description = "The ID of the management server"
  value       = module.management.management_server_id
}

output "management_server_uri" {
  description = "The URI of the Backup DR management console - open this in your browser"
  value       = module.management.management_server_uri
}

output "vpc_id" {
  description = "The ID of the backup VPC"
  value       = module.management.vpc_id
}

output "subnet_id" {
  description = "The ID of the backup subnet"
  value       = module.management.subnet_id
}

output "vault_compute_nonprod_id" {
  description = "The ID of the compute nonprod vault"
  value       = module.vault_compute_nonprod.vault_id
}

output "vault_database_nonprod_id" {
  description = "The ID of the database nonprod vault"
  value       = module.vault_database_nonprod.vault_id
}
