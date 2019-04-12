# terraform-aws-rancher
Terraform module which creates an HA deployment of Rancher inside AWS

## Create a Rancher cluster with public LB and instances

```hcl
module "rancher" {
  source   = "git@github.com:cerebrotech/terraform-aws-rancher"

  vpc_id         = "vpc-id"
  lb_cidr_blocks = ["0.0.0.0/0"]
  lb_subnet_ids  = ["public-subnet-id"]
  subnet_ids     = ["public-subnet-id"]
  ssh_key_name   = "domino-test"

  provisioner_cidr_block = "67.80.87.241/32" # e.g. your IP addr
}
```

## Provision private instances through a bastion host

```hcl
module "rancher" {
  source   = "git@github.com:cerebrotech/terraform-aws-rancher"

  vpc_id         = "vpc-id"
  lb_cidr_blocks = ["0.0.0.0/0"]
  lb_subnet_ids  = ["public-subnet-id"]
  subnet_ids     = ["private-subnet-id"]
  ssh_key_name   = "domino-test"

  ssh_proxy_user = "bastion"
  ssh_proxy_host = "bastion-ip-addr"
  ssh_key_path   = "~/.ssh/domino-test.pem"

  provisioner_security_group = "my-bastion-secgrp-id"
}
```

## Create an internal LB

```hcl
module "rancher" {
  source   = "git@github.com:cerebrotech/terraform-aws-rancher"

  vpc_id             = "vpc-id"
  internal_lb        = true
  lb_security_groups = ["custom-node-secgrp-id"]
  lb_subnet_ids      = ["private-subnet-id"]
  subnet_ids         = ["different-private-subnet-id"]
  ssh_key_name       = "domino-test"

  ssh_proxy_user = "bastion"
  ssh_proxy_host = "bastion-ip-addr"
  ssh_key_path   = "~/.ssh/domino-test.pem"

  provisioner_security_group = "my-bastion-secgrp-id"
}
```

## Leverage the nested Ranchhand module directly

```hcl
module "ranchhand" {
  source   = "git@github.com:cerebrotech/terraform-aws-rancher//modules/ranchhand"

  node_ips         = ["..."]
  distro           = "darwin"
  release          = "latest"
  working_dir      = "..."
  cert_dnsnames    = ["..."]
  cert_ipaddresses = ["..."]

  ssh_username   = "..."
  ssh_key_path   = "..."
  ssh_proxy_user = "..."
  ssh_proxy_host = "..."
}
```
