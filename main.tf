# TODO:
#   - provision rancher servers (can we encapsulate this for reuse?)
#   - set up security groups
#     - instances should only accept 443/80 traffic from LB
#     - lb should attach a provided secgrp
#   - use prefixes so you can launch multiple w/o ambiguity (maybe)

terraform {
  version = "~> 0.11"

  # (v0.12) https://github.com/hashicorp/terraform/issues/16835
  required_providers {
    aws = "~> 2.5"
  }
}

resource "aws_instance" "this" {
  count = "${var.instance_count}"

  ami                     = "${var.ami}"
  placement_group         = "${var.placement_group}"
  ebs_optimized           = "${var.ebs_optimized}"
  instance_type           = "${var.instance_type}"
  key_name                = "${var.key_name}"
  monitoring              = "${var.enable_detailed_monitoring}"
  subnet_id               = "${element(var.subnet_ids, count.index % length(var.subnet_ids))}"
  vpc_security_group_ids  = ["${var.security_group_ids}"]

  disable_api_termination = "${var.enable_deletion_protection}"

  root_block_device {
    volume_size           = "${var.os_disk_size}"
    volume_type           = "${var.os_disk_type}"
    delete_on_termination = "${var.os_disk_delete_on_termination}"
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-${count.index}", "Terraform", "true"))}"
}

resource "aws_lb" "this" {
  name               = "${var.name}-lb"
  internal           = "${var.internal_lb}"
  load_balancer_type = "network"
  # security_groups    = [""]
  subnets            = ["${var.subnet_ids}"]

  enable_deletion_protection = "${var.enable_deletion_protection}"

  tags = "${merge(var.tags, map("Name", "${var.name}-lb", "Terraform", "true"))}"
}

resource "aws_lb_target_group" "443" {
  name        = "${var.name}-tcp-443"
  port        = 443
  protocol    =  "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  health_check {
    interval            = 10
    path                = "/healthz"
    port                = 80
    protocol            = "HTTP"
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-tcp-443", "Terraform", "true"))}"
}

resource "aws_lb_target_group" "80" {
  name        = "${var.name}-tcp-80"
  port        = 80
  protocol    =  "TCP"
  target_type = "instance"
  vpc_id      = "${var.vpc_id}"

  health_check {
    interval            = 10
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-tcp-80", "Terraform", "true"))}"
}

resource "aws_lb_target_group_attachment" "443" {
  count = "${var.instance_count}"

  target_group_arn = "${aws_lb_target_group.443.arn}"
  target_id        = "${element(aws_instance.this.*.id, count.index)}"
}

resource "aws_lb_target_group_attachment" "80" {
  count = "${var.instance_count}"

  target_group_arn = "${aws_lb_target_group.80.arn}"
  target_id        = "${element(aws_instance.this.*.id, count.index)}"
}
