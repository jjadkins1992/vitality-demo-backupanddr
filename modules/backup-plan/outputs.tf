output "backup_plan_id" {
  description = "The full ID of the backup plan."
  value       = google_backup_dr_backup_plan.plan.id
}

output "backup_plan_name" {
  description = "The name of the backup plan."
  value       = google_backup_dr_backup_plan.plan.name
}

output "association_id" {
  description = "The full ID of the backup plan association."
  value       = google_backup_dr_backup_plan_association.assoc.id
}
