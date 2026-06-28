resource "google_backup_dr_backup_vault" "vault" {
  project                                    = var.project_id
  location                                   = var.location
  backup_vault_id                            = var.vault_name
  description                                = var.description
  backup_minimum_enforced_retention_duration = "${var.retention_days * 86400}s"

  # Sandbox teardown flags - allow terraform destroy to remove the vault even
  # when it still holds non-expired backups. REMOVE/disable for Vitality prod
  # where retention must stay locked for immutability.
  force_update                  = var.force_delete
  force_delete                  = var.force_delete
  ignore_inactive_datasources   = var.force_delete
  ignore_backup_plan_references = var.force_delete

  labels = {
    environment = var.environment
    managed-by  = "terraform"
    tier        = var.tier
  }
}
