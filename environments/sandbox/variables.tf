variable "management_project_id" {
  type    = string
  default = "bkp-dr-mgmt-test-01"
}
variable "workload_project_id" {
  type    = string
  default = "bkp-dr-wl-test-01"
}
variable "region" {
  type    = string
  default = "us-central1"
}
variable "zone" {
  type    = string
  default = "us-central1-a"
}
variable "subnet_cidr" {
  type    = string
  default = "10.232.242.0/24"
}
variable "nonprod_retention_days" {
  type    = number
  default = 1
}
variable "prod_retention_days" {
  type    = number
  default = 1
}
variable "devops_group_id" {
  type    = string
  default = "18d76b0f-3516-4af8-bbc1-aa92b26e5644"
}
variable "dba_group_id" {
  type    = string
  default = "b4c3b565-e9ec-4469-aef3-05516a2bd3a2"
}

variable "force_delete" {
  description = "Sandbox only - allow terraform destroy to bypass vault retention. Set false for prod."
  type        = bool
  default     = false
}
