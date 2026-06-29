# ---------------------------------------------------------------------------
# backup-plan module
#
# Codifies what was previously done by gcloud CLI:
#   1. a backup plan (lives in the MANAGEMENT project, targets a vault)
#   2. a backup plan association (lives in the WORKLOAD project, binds a
#      specific resource to the plan)
#
# Both resources require the google-beta provider.
#
# Validated findings baked in:
#   - the association MUST be created in the workload project (same project as
#     the resource), even though it references a plan in the management project.
#   - resource paths differ:
#       compute : projects/<wp>/zones/<zone>/instances/<name>
#       cloudsql: projects/<wp>/instances/<name>   (no zone)
#   - backup window minimum is 6 hours.
# ---------------------------------------------------------------------------

resource "google_backup_dr_backup_plan" "plan" {
  provider = google-beta

  project        = var.management_project_id
  location       = var.location
  backup_plan_id = var.plan_id
  resource_type  = var.resource_type
  backup_vault   = var.backup_vault_id

  backup_rules {
    rule_id               = var.rule_id
    backup_retention_days = var.retention_days

    standard_schedule {
      recurrence_type  = var.recurrence_type
      hourly_frequency = var.hourly_frequency
      time_zone        = var.time_zone

      backup_window {
        start_hour_of_day = var.window_start_hour
        end_hour_of_day   = var.window_end_hour
      }
    }
  }
}

resource "google_backup_dr_backup_plan_association" "assoc" {
  provider = google-beta

  # NOTE: project is the WORKLOAD project - same as the resource being
  # protected - not the management project where the plan lives.
  project                  = var.workload_project_id
  location                 = var.location
  backup_plan_association_id = var.association_id
  resource                 = var.resource
  resource_type            = var.resource_type
  backup_plan              = google_backup_dr_backup_plan.plan.name

  depends_on = [google_backup_dr_backup_plan.plan]
}
