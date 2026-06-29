# ---------------------------------------------------------------------------
# workload-iam module
#
# Codifies the cross-project IAM grants previously done by gcloud CLI.
#
# Validated finding: Compute and Cloud SQL backups use DIFFERENT Backup and DR
# service agents on the management project, and EACH needs its own operator
# role granted on the WORKLOAD project. Granting one does not cover the other.
#
#   compute agent -> roles/backupdr.computeEngineOperator
#   sql agent     -> roles/backupdr.cloudSqlOperator
#
# IMPORTANT - the service agent email suffix (e.g. ...-86854037) is derived per
# project and is NOT predictable from Terraform. The agent emails must be
# supplied as inputs (read once from the console or from a prior apply's error
# output), or resolved out-of-band. They are therefore variables here rather
# than computed. See README for how to obtain them.
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "compute_operator" {
  count   = var.compute_agent_email == "" ? 0 : 1
  project = var.workload_project_id
  role    = "roles/backupdr.computeEngineOperator"
  member  = "serviceAccount:${var.compute_agent_email}"
}

resource "google_project_iam_member" "cloudsql_operator" {
  count   = var.cloudsql_agent_email == "" ? 0 : 1
  project = var.workload_project_id
  role    = "roles/backupdr.cloudSqlOperator"
  member  = "serviceAccount:${var.cloudsql_agent_email}"
}
