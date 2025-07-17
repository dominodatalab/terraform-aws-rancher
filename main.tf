terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# #------------------------------------------------------------------------------
# # EC2 instances
# #------------------------------------------------------------------------------
resource "aws_instance" "rke2_server" {
  count                   = var.server_count
  ami                     = data.aws_ami.ubuntu.id
  instance_type           = var.server_instance_type
  key_name                = var.ssh_key_name
  monitoring              = var.enable_detailed_monitoring
  disable_api_termination = var.enable_deletion_protection
  subnet_id               = var.subnet_ids[count.index]
  user_data               = data.cloudinit_config.rke2_server_userdata.rendered

  vpc_security_group_ids = [
    aws_security_group.rke2_server.id
  ]

  root_block_device {
    volume_size           = var.os_disk_size
    volume_type           = var.os_disk_type
    delete_on_termination = var.os_disk_delete_on_termination
    encrypted             = var.os_disk_encrypted
    kms_key_id            = var.os_disk_kms_key_id
  }

  lifecycle {
    ignore_changes = [ami, root_block_device]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = merge(
    local.tags,
    {
      "Name"      = "${var.name}-${count.index}"
      "Terraform" = "true"
      "rke2-role" = count.index == 0 ? "server" : "agent"
    },
  )

  volume_tags = local.tags

}


# #------------------------------------------------------------------------------
# # Load balancer
# #------------------------------------------------------------------------------
resource "aws_elb" "rke2_server" {
  name            = "rke2-server-lb"
  internal        = true
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.rke2_server.id, aws_security_group.rke2_agent.id]

  # listener {
  #   instance_port     = 443
  #   instance_protocol = "TCP"
  #   lb_port           = 443
  #   lb_protocol       = "TCP"
  # }

  # listener {
  #   instance_port     = 80
  #   instance_protocol = "TCP"
  #   lb_port           = 80
  #   lb_protocol       = "TCP"
  # }

  # RKE2 API server listener
  listener {
    instance_port     = 6443
    instance_protocol = "TCP"
    lb_port           = 6443
    lb_protocol       = "TCP"
  }

  # RKE2 supervisor port for HA
  listener {
    instance_port     = 9345
    instance_protocol = "TCP"
    lb_port           = 9345
    lb_protocol       = "TCP"
  }

  # RKE2 kubelet port
  listener {
    instance_port     = 10250
    instance_protocol = "TCP"
    lb_port           = 10250
    lb_protocol       = "TCP"
  }

  # RKE2 etcd port
  listener {
    instance_port     = 2379
    instance_protocol = "TCP"
    lb_port           = 2379
    lb_protocol       = "TCP"
  }
  # RKE2 etcd port
  listener {
    instance_port     = 2380
    instance_protocol = "TCP"
    lb_port           = 2380
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    target              = "HTTP:6443/healthz"
    interval            = 10
    timeout             = 6
  }

  tags = {
    Name = "rke2-server-nlb"
  }
}

resource "aws_lb_target_group" "rke2_api" {
  name     = "rke2-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    port                = 6443
    protocol            = "TCP"
  }

  tags = local.tags
}

resource "aws_lb_target_group" "rke2_server" {
  name     = "rke2-server-tg"
  port     = 9345 # RKE2 uses 9345 (server), 6443 (API), 10250 (kubelet), 2379-2380 (etcd)
  protocol = "TCP"
  vpc_id   = var.vpc_id


  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    port                = 9345
    protocol            = "TCP"
  }

  tags = local.tags
}

# #------------------------------------------------------------------------------
# # Security groups
# #------------------------------------------------------------------------------
resource "aws_security_group" "rke2_server" {
  name_prefix = "rke2-server-"
  vpc_id      = local.vpc_id

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # RKE2 server port
  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # etcd peer communication
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # Canal CNI
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # Kubelet
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "rke2_agent" {
  name_prefix = "rke2-agent-"
  vpc_id      = var.vpc_id

  # Kubelet
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # Canal CNI
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [local.vpc_cidrs]
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidrs] #[var.allowed_cidrs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# resource "aws_security_group" "loadbalancer" {
#   name        = local.lb_secgrp_name
#   description = "Grant access to Rancher ELB"
#   vpc_id      = var.vpc_id

#   tags = merge(
#     local.tags,
#     {
#       "Name"      = local.lb_secgrp_name
#       "Terraform" = "true"
#     },
#   )
# }

# # Existing load balancer rules for Rancher (443, 80)
# resource "aws_security_group_rule" "lb_rancher_ingress_443" {
#   description = "ingress port 443 - loadbalancer ${aws_security_group.loadbalancer.id}"
#   type      = "ingress"
#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# resource "aws_security_group_rule" "lb_rancher_ingress_80" {
#   description = "ingress port 80 - loadbalancer ${aws_security_group.loadbalancer.id}"
#   type      = "ingress"
#   from_port = 80
#   to_port   = 80
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# # RKE2 API server ingress rules
# resource "aws_security_group_rule" "lb_rke2_ingress_6443" {
#   description = "ingress port 6443 - RKE2 API server"
#   type      = "ingress"
#   from_port = 6443
#   to_port   = 6443
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# # RKE2 supervisor port ingress rules
# resource "aws_security_group_rule" "lb_rke2_ingress_9345" {
#   description = "ingress port 9345 - RKE2 supervisor"
#   type      = "ingress"
#   from_port = 9345
#   to_port   = 9345
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# resource "aws_security_group_rule" "lb_cidr_ingress_443" {
#   count = length(var.lb_cidr_blocks)
#   description = "ingress port 443 - ${var.lb_cidr_blocks[count.index]}"

#   type      = "ingress"
#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   security_group_id = aws_security_group.loadbalancer.id
#   cidr_blocks       = var.lb_cidr_blocks
# }

# resource "aws_security_group_rule" "lb_secgrp_ingress_443" {
#   count = var.lb_security_groups_count
#   description = "${var.lb_security_groups[count.index]} ingress port 443"

#   type      = "ingress"
#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = var.lb_security_groups[count.index]
# }

# resource "aws_security_group_rule" "lb_cidr_ingress_80" {
#   count = length(var.lb_cidr_blocks)
#   description = "ingress port 80 - ${var.lb_cidr_blocks[count.index]}"

#   type      = "ingress"
#   from_port = 80
#   to_port   = 80
#   protocol  = "tcp"

#   security_group_id = aws_security_group.loadbalancer.id
#   cidr_blocks       = var.lb_cidr_blocks
# }

# resource "aws_security_group_rule" "lb_secgrp_ingress_80" {
#   count = var.lb_security_groups_count
#   description = "${var.lb_security_groups[count.index]} ingress port 80"

#   type      = "ingress"
#   from_port = 80
#   to_port   = 80
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = var.lb_security_groups[count.index]
# }

# # RKE2 API server CIDR ingress rules
# resource "aws_security_group_rule" "lb_cidr_ingress_6443" {
#   count = length(var.lb_cidr_blocks)
#   description = "ingress port 6443 - RKE2 API - ${var.lb_cidr_blocks[count.index]}"

#   type      = "ingress"
#   from_port = 6443
#   to_port   = 6443
#   protocol  = "tcp"

#   security_group_id = aws_security_group.loadbalancer.id
#   cidr_blocks       = var.lb_cidr_blocks
# }

# resource "aws_security_group_rule" "lb_secgrp_ingress_6443" {
#   count = var.lb_security_groups_count
#   description = "${var.lb_security_groups[count.index]} ingress port 6443 - RKE2 API"

#   type      = "ingress"
#   from_port = 6443
#   to_port   = 6443
#   protocol  = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = var.lb_security_groups[count.index]
# }

# resource "aws_security_group_rule" "lb_egress_443" {
#   type        = "egress"
#   description = "Outgoing instance traffic"
#   from_port   = 443
#   to_port     = 443
#   protocol    = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# resource "aws_security_group_rule" "lb_egress_80" {
#   type        = "egress"
#   description = "Outgoing instance traffic"
#   from_port   = 80
#   to_port     = 80
#   protocol    = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# # RKE2 egress rules
# resource "aws_security_group_rule" "lb_egress_6443" {
#   type        = "egress"
#   description = "Outgoing RKE2 API traffic"
#   from_port   = 6443
#   to_port     = 6443
#   protocol    = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# resource "aws_security_group_rule" "lb_egress_9345" {
#   type        = "egress"
#   description = "Outgoing RKE2 supervisor traffic"
#   from_port   = 9345
#   to_port     = 9345
#   protocol    = "tcp"

#   security_group_id        = aws_security_group.loadbalancer.id
#   source_security_group_id = aws_security_group.instances.id
# }

# resource "aws_security_group" "instances" {
#   name        = local.instance_secgrp_name
#   description = "Govern access to Rancher server instances"
#   vpc_id      = var.vpc_id

#   ingress {
#     description     = "Incoming LB traffic"
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.loadbalancer.id]
#   }

#   ingress {
#     description     = "Incoming LB traffic"
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.loadbalancer.id]
#   }

#   # RKE2 API server
#   ingress {
#     description     = "RKE2 API server"
#     from_port       = 6443
#     to_port         = 6443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.loadbalancer.id]
#   }

#   # RKE2 supervisor port for HA
#   ingress {
#     description     = "RKE2 supervisor port"
#     from_port       = 9345
#     to_port         = 9345
#     protocol        = "tcp"
#     security_groups = [aws_security_group.loadbalancer.id]
#   }

#   # RKE2 etcd client port
#   ingress {
#     description = "RKE2 etcd client"
#     from_port   = 2379
#     to_port     = 2379
#     protocol    = "tcp"
#     self        = true
#   }

#   # RKE2 etcd peer port
#   ingress {
#     description = "RKE2 etcd peer"
#     from_port   = 2380
#     to_port     = 2380
#     protocol    = "tcp"
#     self        = true
#   }

#   # RKE2 kubelet
#   ingress {
#     description = "RKE2 kubelet"
#     from_port   = 10250
#     to_port     = 10250
#     protocol    = "tcp"
#     self        = true
#   }

#   # RKE2 CNI (Flannel VXLAN)
#   ingress {
#     description = "RKE2 CNI VXLAN"
#     from_port   = 8472
#     to_port     = 8472
#     protocol    = "udp"
#     self        = true
#   }

#   # RKE2 metrics server
#   ingress {
#     description = "RKE2 metrics server"
#     from_port   = 10254
#     to_port     = 10254
#     protocol    = "tcp"
#     self        = true
#   }

#   # NodePort services
#   ingress {
#     description = "NodePort services"
#     from_port   = 30000
#     to_port     = 32767
#     protocol    = "tcp"
#     self        = true
#   }

#   ingress {
#     description = "Node intercommunication"
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     self        = true
#   }

#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     local.tags,
#     {
#       "Name"      = local.instance_secgrp_name
#       "Terraform" = "true"
#     },
#   )
# }


# resource "aws_security_group_rule" "provisioner_cidr_ingress_22" {
#   count = var.use_provisioner_secgrp ? 0 : 1

#   type        = "ingress"
#   description = "RKE2 SSH access"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"

#   security_group_id = aws_security_group.provisioner.id
#   cidr_blocks       = [var.provisioner_cidr_block]
# }

# resource "aws_security_group_rule" "provisioner_secgrp_ingress_22" {
#   count = var.use_provisioner_secgrp ? 1 : 0

#   type        = "ingress"
#   description = "RKE2 SSH access"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"

#   security_group_id        = aws_security_group.provisioner.id
#   source_security_group_id = var.provisioner_security_group
# }

# resource "aws_security_group_rule" "provisioner_cidr_ingress_6443" {
#   count = var.use_provisioner_secgrp ? 0 : 1

#   type        = "ingress"
#   description = "RKE2 K8s endpoint verification"
#   from_port   = 6443
#   to_port     = 6443
#   protocol    = "tcp"

#   security_group_id = aws_security_group.provisioner.id
#   cidr_blocks       = [var.provisioner_cidr_block]
# }
