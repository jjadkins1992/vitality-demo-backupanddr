output "vault_id" {
  description = "The ID of the backup vault"
  value       = google_backup_dr_backup_vault.vault.id
}
output "vault_name" {
  description = "The name of the backup vault"
  value       = google_backup_dr_backup_vault.vault.backup_vault_id
}
output "vault_state" {
  description = "The state of the backup vault"
  value       = google_backup_dr_backup_vault.vault.state
}
