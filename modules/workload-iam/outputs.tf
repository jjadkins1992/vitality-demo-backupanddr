output "compute_binding" {
  description = "The compute operator IAM binding, if created."
  value       = var.compute_agent_email == "" ? null : google_project_iam_member.compute_operator[0].id
}

output "cloudsql_binding" {
  description = "The Cloud SQL operator IAM binding, if created."
  value       = var.cloudsql_agent_email == "" ? null : google_project_iam_member.cloudsql_operator[0].id
}
