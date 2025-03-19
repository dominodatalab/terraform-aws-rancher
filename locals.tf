locals {
  vpc_cidrs = data.aws_vpc.this.cidr_block_associations[*].cidr_block
  vpc_id    = data.aws_vpc.this.id

  ami_id = var.ami != "" ? var.ami : data.aws_ami.ubuntu.id

  # Per https://docs.rke2.io/reference/https://docs.rke2.io/reference/server_config
  # these values must be the same on all servers in the cluster
  agent_token              = var.rke2_token != "" ? var.rke2_token : random_string.rke2_token.result
  cluster_cidr             = var.cluster_cidr != "" ? var.cluster_cidr : "10.42.0.0/16"
  cluster_dns              = var.cluster_dns != "" ? var.cluster_dns : "10.43.0.10"
  cluster_domain           = var.cluster_domain
  disable_cloud_controller = false
  disable_kube_proxy       = false
  egress_selector_mode     = "agent"
  service_cidr             = var.service_cidr != "" ? var.service_cidr : "10.43.0.0/16"

  tags = merge(var.tags)
}
