output "lb_dns_name" {
  description = "DNS name for load balancer managing Rancher traffic"
  value       = "${aws_elb.this.dns_name}"
}

output "cluster_provisioned" {
  description = "Blah blah"
  value       = "${module.ranchhand.cluster_provisioned}"
}
