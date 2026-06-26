resource "google_backup_dr_backup_vault" "vault" {
  project                                    = var.project_id
  location                                   = var.location
  backup_vault_id                            = var.vault_name
  description                                = var.description
  backup_minimum_enforced_retention_duration = "${var.retention_days * 86400}s"
  labels = {
    environment = var.environment
    managed-by  = "terraform"
    tier        = var.tier
  }
}
