variable "management_project_id" {
  description = "Project ID for the Backup and DR management project"
  type        = string
}
variable "workload_project_id" {
  description = "Project ID for the workload project being protected"
  type        = string
}
variable "region" {
  description = "Primary region for Backup and DR deployment"
  type        = string
  default     = "us-central1"
}
variable "zone" {
  description = "Zone for the Backup Appliance VM"
  type        = string
  default     = "us-central1-a"
}
variable "network_name" {
  description = "VPC network name for the Backup Appliance"
  type        = string
  default     = "default"
}
variable "subnet_name" {
  description = "Subnet name for the Backup Appliance"
  type        = string
  default     = "default"
}
variable "nonprod_retention_days" {
  description = "Minimum retention in days for non-production backups"
  type        = number
  default     = 30
}
variable "prod_retention_days" {
  description = "Minimum retention in days for production backups"
  type        = number
  default     = 90
}
variable "devops_group_id" {
  description = "Workforce pool group ID for DevOps Admin"
  type        = string
}
variable "dba_group_id" {
  description = "Workforce pool group ID for DBA Admin"
  type        = string
}
