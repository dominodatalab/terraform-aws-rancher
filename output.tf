output "lb_dns_name" {
  description = "DNS name for load balancer managing Rancher traffic"
  value       = aws_elb.this.dns_name
}

output "cluster_provisioned" {
  description = "ID of the null_resource cluster provisioner"
  value       = module.rke2_provisioner.cluster_provisioned
}

output "admin_password" {
  description = "Generated Rancher admin user password"
  value       = module.rke2_provisioner.admin_password
  sensitive   = true
}

output "kubeconfig_file" {
  description = "Path to the generated kubeconfig file"
  value       = module.rke2_provisioner.kubeconfig_file
}
