variable "project_id" {
  description = "Project ID where the vault will be created"
  type        = string
}
variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}
variable "location" {
  description = "Location for the vault - region for single-region or e.g. eu for multi-region"
  type        = string
}
variable "description" {
  description = "Description of the vault"
  type        = string
  default     = "Managed by Terraform"
}
variable "retention_days" {
  description = "Minimum enforced retention period in days"
  type        = number
}
variable "environment" {
  description = "Environment label - prod or nonprod"
  type        = string
}
variable "tier" {
  description = "Workload tier - compute or database"
  type        = string
  default     = "compute"
}
