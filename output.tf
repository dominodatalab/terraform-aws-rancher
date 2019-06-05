output "lb_dns_name" {
  description = "DNS name for load balancer managing Rancher traffic"
  value       = "${aws_elb.this.dns_name}"
}

output "cluster_provisioned" {
  description = "ID of the null_resource cluster provisioner"
  value       = "${module.ranchhand.cluster_provisioned}"
}

output "admin_password" {
  description = "Generated Rancher admin user password"
  value       = "${var.admin_password == "" ? module.ranchhand.admin_password : var.admin_password}"
}
