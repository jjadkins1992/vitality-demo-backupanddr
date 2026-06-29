variable "management_project_id" {
  description = "Project where the backup plan lives (same as the vaults)."
  type        = string
}

variable "workload_project_id" {
  description = "Project where the protected resource lives. The association is created here."
  type        = string
}

variable "location" {
  description = "Region for the plan and association, e.g. us-central1."
  type        = string
}

variable "plan_id" {
  description = "Name of the backup plan, e.g. bp-compute-nonprod."
  type        = string
}

variable "association_id" {
  description = "Name of the backup plan association, e.g. test-vm-assoc."
  type        = string
}

variable "resource_type" {
  description = "compute.googleapis.com/Instance or sqladmin.googleapis.com/Instance."
  type        = string
}

variable "backup_vault_id" {
  description = "Full resource name of the target vault (from the vault module output)."
  type        = string
}

variable "resource" {
  description = <<-EOT
    Full path of the protected resource.
      compute : projects/<wp>/zones/<zone>/instances/<name>
      cloudsql: projects/<wp>/instances/<name>
  EOT
  type        = string
}

variable "rule_id" {
  description = "Backup rule id."
  type        = string
  default     = "daily-6h"
}

variable "retention_days" {
  description = "Backup retention in days. Must be >= the vault's minimum enforced retention."
  type        = number
}

variable "recurrence_type" {
  description = "HOURLY, DAILY, WEEKLY, MONTHLY, or YEARLY."
  type        = string
  default     = "HOURLY"
}

variable "hourly_frequency" {
  description = "For HOURLY recurrence, how many hours between backups. Minimum window is 6h."
  type        = number
  default     = 6
}

variable "time_zone" {
  description = "Time zone for the schedule."
  type        = string
  default     = "UTC"
}

variable "window_start_hour" {
  description = "Backup window start hour of day (0-23)."
  type        = number
  default     = 0
}

variable "window_end_hour" {
  description = "Backup window end hour of day (1-24). Window must be at least 6 hours."
  type        = number
  default     = 24
}
