data "template_file" "rke2_server_userdata" {
  template = file("${path.module}/cloud-init/rke2-server.yaml")
  vars = {
    cluster_cidr = local.cluster_cidr
    cni          = var.cni_plugin
    node_taint   = var.node_taint
    rke2_token   = var.rke2_token
    server_url   = var.rke2_server_url # Only for additional servers
    service_cidr = local.service_cidr
  }
}

data "template_file" "rke2_agent_userdata" {
  template = file("${path.module}/cloud-init/rke2-agent.yaml")
  vars = {
    cluster_cidr = local.cluster_cidr
    cni          = var.cni_plugin
    node_taint   = var.node_taint
    rke2_token   = var.rke2_token
    server_url   = var.rke2_server_url # Only for additional servers
    service_cidr = local.service_cidr
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/${var.node_os_version}-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "this" {
  id = var.vpc_id
}
