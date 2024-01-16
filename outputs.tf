# ====================================================== nginx-proxy-manager ===


# ================================================================ resources ===

output "security_group_id" {
  value       = module.security_group.id
  description = "The ID of the security group created for the Teleport service."
}

output "security_group_name" {
  value       = module.security_group.name
  description = "The name of the security group created for the Teleport service."
}
