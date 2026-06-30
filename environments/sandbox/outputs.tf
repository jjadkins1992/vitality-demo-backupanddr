output "management_server_id" {
  value = module.management.management_server_id
}
output "management_server_uri" {
  value = module.management.management_server_uri
}
output "vpc_id" {
  value = module.network.vpc_id
}
output "region_subnets" {
  value = { for k, m in module.region : k => m.subnet_id }
}
output "vault_ids" {
  value = { for k, m in module.vault : k => m.vault_id }
}

output "management_server_api" {
  value = module.management.management_server_api
}
