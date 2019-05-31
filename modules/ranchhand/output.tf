output "cluster_provisioned" {
  value = "${null_resource.provisioner.id}"
}

output "admin_password" {
  description = "Generated password for Rancher default admin user"
  value       = "${random_string.password.result}"
}
