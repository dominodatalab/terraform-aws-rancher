locals {
  lb_name                 = "${var.name}-lb-${var.internal_lb ? "int" : "ext"}"
  lb_secgrp_name          = "${var.name}-lb"
  instance_secgrp_name    = "${var.name}-instances"
  provisioner_secgrp_name = "${var.name}-provisioner"
}

#------------------------------------------------------------------------------
# EC2 instances
#------------------------------------------------------------------------------
resource "aws_instance" "this" {
  count = var.instance_count

  ami                     = var.ami
  ebs_optimized           = var.ebs_optimized
  instance_type           = var.instance_type
  key_name                = var.ssh_key_name
  monitoring              = var.enable_detailed_monitoring
  subnet_id               = element(var.subnet_ids, count.index % length(var.subnet_ids))
  disable_api_termination = var.enable_deletion_protection

  vpc_security_group_ids = [
    aws_security_group.instances.id,
    aws_security_group.provisioner.id,
  ]

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_size           = var.os_disk_size
    volume_type           = var.os_disk_type
    delete_on_termination = var.os_disk_delete_on_termination
  }

  tags = merge(
    var.tags,
    {
      "Name"      = "${var.name}-${count.index}"
      "Terraform" = "true"
    },
  )
}

#------------------------------------------------------------------------------
# Load balancer
#------------------------------------------------------------------------------
resource "aws_elb" "this" {
  name            = local.lb_name
  security_groups = [aws_security_group.loadbalancer.id]
  subnets         = var.lb_subnet_ids
  instances       = aws_instance.this.*.id
  internal        = var.internal_lb
  idle_timeout    = 3600

  listener {
    instance_port     = 443
    instance_protocol = "TCP"
    lb_port           = 443
    lb_protocol       = "TCP"
  }

  listener {
    instance_port     = 80
    instance_protocol = "TCP"
    lb_port           = 80
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    target              = "HTTP:80/healthz"
    interval            = 10
    timeout             = 6
  }

  tags = merge(
    var.tags,
    {
      "Name"      = local.lb_name
      "Terraform" = "true"
    },
  )
}

#------------------------------------------------------------------------------
# Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "loadbalancer" {
  name        = local.lb_secgrp_name
  description = "Grant access to Rancher ELB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name"      = local.lb_secgrp_name
      "Terraform" = "true"
    },
  )
}

resource "aws_security_group_rule" "lb_rancher_ingress_443" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "lb_rancher_ingress_80" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "lb_cidr_ingress_443" {
  count = length(var.lb_cidr_blocks)

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id = aws_security_group.loadbalancer.id
  cidr_blocks       = var.lb_cidr_blocks
}

resource "aws_security_group_rule" "lb_secgrp_ingress_443" {
  count = var.lb_security_groups_count

  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = var.lb_security_groups[count.index]
}

resource "aws_security_group_rule" "lb_cidr_ingress_80" {
  count = length(var.lb_cidr_blocks)

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  security_group_id = aws_security_group.loadbalancer.id
  cidr_blocks       = var.lb_cidr_blocks
}

resource "aws_security_group_rule" "lb_secgrp_ingress_80" {
  count = var.lb_security_groups_count

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = var.lb_security_groups[count.index]
}

resource "aws_security_group_rule" "lb_egress_443" {
  type        = "egress"
  description = "Outgoing instance traffic"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "lb_egress_80" {
  type        = "egress"
  description = "Outgoing instance traffic"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"

  security_group_id        = aws_security_group.loadbalancer.id
  source_security_group_id = aws_security_group.instances.id
}

resource "aws_security_group" "instances" {
  name        = local.instance_secgrp_name
  description = "Govern access to Rancher server instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Incoming LB traffic"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer.id]
  }

  ingress {
    description     = "Incoming LB traffic"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer.id]
  }

  ingress {
    description = "Node intercommunication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name"      = local.instance_secgrp_name
      "Terraform" = "true"
    },
  )
}

resource "aws_security_group" "provisioner" {
  name        = local.provisioner_secgrp_name
  description = "Provision Rancher instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name"      = local.provisioner_secgrp_name
      "Terraform" = "true"
    },
  )
}

resource "aws_security_group_rule" "provisioner_cidr_ingress_22" {
  count = var.use_provisioner_secgrp ? 0 : 1

  type        = "ingress"
  description = "RKE SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"

  security_group_id = aws_security_group.provisioner.id
  cidr_blocks       = [var.provisioner_cidr_block]
}

resource "aws_security_group_rule" "provisioner_secgrp_ingress_22" {
  count = var.use_provisioner_secgrp ? 1 : 0

  type        = "ingress"
  description = "RKE SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"

  security_group_id        = aws_security_group.provisioner.id
  source_security_group_id = var.provisioner_security_group
}

resource "aws_security_group_rule" "provisioner_cidr_ingress_6443" {
  count = var.use_provisioner_secgrp ? 0 : 1

  type        = "ingress"
  description = "RKE K8s endpoint verification"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"

  security_group_id = aws_security_group.provisioner.id
  cidr_blocks       = [var.provisioner_cidr_block]
}

resource "aws_security_group_rule" "provisioner_secgrp_ingress_6443" {
  count = var.use_provisioner_secgrp ? 1 : 0

  type        = "ingress"
  description = "RKE K8s endpoint verification"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"

  security_group_id        = aws_security_group.provisioner.id
  source_security_group_id = var.provisioner_security_group
}

resource "aws_security_group_rule" "provisioner_cidr_ingress_443" {
  count = var.use_provisioner_secgrp ? 0 : 1

  type        = "ingress"
  description = "Ranchhand cluster verification"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"

  security_group_id = aws_security_group.provisioner.id
  cidr_blocks       = [var.provisioner_cidr_block]
}

resource "aws_security_group_rule" "provisioner_secgrp_ingress_443" {
  count = var.use_provisioner_secgrp ? 1 : 0

  type        = "ingress"
  description = "Ranchhand cluster verification"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"

  security_group_id        = aws_security_group.provisioner.id
  source_security_group_id = var.provisioner_security_group
}

#------------------------------------------------------------------------------
# Provisioner
#------------------------------------------------------------------------------
module "ranchhand" {
  source = "github.com/dominodatalab/ranchhand.git//terraform?ref=v0.1.2-rc1""

  node_ips = split(
    ",",
    replace(
      join(
        ",",
        formatlist(
          "%s:%s",
          aws_instance.this.*.public_ip,
          aws_instance.this.*.private_ip,
        ),
      ),
      "/^:|(,):/",
      "$1",
    ),
  )

  distro           = var.ranchhand_distro
  release          = var.ranchhand_release
  working_dir      = var.ranchhand_working_dir
  cert_dnsnames    = concat([aws_elb.this.dns_name], var.cert_dnsnames)
  cert_ipaddresses = var.cert_ipaddresses

  ssh_username   = var.ssh_username
  ssh_key_path   = var.ssh_key_path
  ssh_proxy_user = var.ssh_proxy_user
  ssh_proxy_host = var.ssh_proxy_host

  admin_password = var.admin_password
}

