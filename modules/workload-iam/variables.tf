variable "workload_project_id" {
  description = "The workload project where protected resources live and where the grants are applied."
  type        = string
}

variable "compute_agent_email" {
  description = <<-EOT
    Email of the Backup and DR COMPUTE service agent, of the form
    vault-<mgmt-project-number>-<id>@gcp-sa-backupdr-pr.iam.gserviceaccount.com.
    Leave blank ("") to skip the compute grant.
  EOT
  type        = string
  default     = ""
}

variable "cloudsql_agent_email" {
  description = <<-EOT
    Email of the Backup and DR CLOUD SQL service agent (a DIFFERENT agent from
    compute), of the same form. Leave blank ("") to skip the Cloud SQL grant.
  EOT
  type        = string
  default     = ""
}
