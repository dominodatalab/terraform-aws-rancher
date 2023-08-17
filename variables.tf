#------------------------------------------------------------------------------
# REQUIRED
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC where resources should be created"
}

variable "lb_subnet_ids" {
  description = "List of subnets where LB will be created"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnets where instances will be created"
  type        = list(string)
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to use for the instances"
}

#------------------------------------------------------------------------------
# YOU MUST CHOOSE ONE OF THE FOLLOWING OTHERWISE PROVISIONING WILL FAIL!
#------------------------------------------------------------------------------
variable "use_provisioner_secgrp" {
  description = "Determines whether to use the security provision_security_group or provisioner_cidr_block inputs."
  default     = "true"
}

variable "provisioner_security_group" {
  description = "ID of security group attached to the VM that will provision the Rancher instances. This is typically a bastion host."
  default     = ""
}

variable "provisioner_cidr_block" {
  description = "CIDR address of the host that will provision the Rancher instances. This will only work with instances that are publicly accessible."
  default     = ""
}

#------------------------------------------------------------------------------
# OPTIONAL
#------------------------------------------------------------------------------
variable "name" {
  description = "Root name applied to all resources"
  default     = "rancher"
}

variable "internal_lb" {
  description = "Create an internal load balancer. Defaults to internet-facing."
  default     = false
}

variable "lb_security_groups" {
  description = "Grant LB ingress access to one or more security group IDs"
  default     = []
}

variable "lb_security_groups_count" {
  description = "Count of dynamically determines lb_security_groups"
  default     = 0
}

variable "lb_cidr_blocks" {
  description = "Grant LB ingress access to one or more CIDR addresses"
  default     = []
}

variable "instance_count" {
  description = "Number of instances to launch"
  default     = 3
}

variable "ami" {
  description = "Instance AMI defaults to Ubuntu 16.04"
  default     = "ami-0565af6e282977273"
}

variable "instance_type" {
  description = "Type of instances to launch"
  default     = "t3.xlarge"
}

variable "os_disk_size" {
  description = "Root partition volume size for instances"
  default     = 30
}

variable "os_disk_type" {
  description = "Root partition volume type for instances"
  default     = "gp3"
}

variable "os_disk_delete_on_termination" {
  description = "Destroy root EBS volume when instances are terminated"
  default     = true
}

variable "os_disk_encrypted" {
  description = "Encrypt root EBS volume"
  default     = true
}

variable "os_disk_kms_key_id" {
  description = "Optional encryption key for root EBS volume"
  default     = ""
}

variable "ebs_optimized" {
  description = "Attach NICs dedicated to EBS volume network traffic"
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Launch EC2 instances with detailed monitoring enabled"
  default     = false
}

variable "enable_deletion_protection" {
  description = ""
  default     = false
}

variable "tags" {
  description = "Extra tags assigned to all resources"
  default     = {}
}

#------------------------------------------------------------------------------
# RANCHHAND
#------------------------------------------------------------------------------
variable "ranchhand_working_dir" {
  description = "Directory where ranchhand should be executed. Defaults to the current working directory."
  default     = ""
}

variable "cert_dnsnames" {
  description = "Hostnames for the rancher and rke ssl certs (comma-delimited)"
  default     = [""]
}

variable "cert_ipaddresses" {
  description = "IP addresses for the rancher and rke ssl certs (comma-delimited)"
  default     = ["127.0.0.1"]
}

variable "ssh_username" {
  description = "SSH username on the nodes"
  default     = "ubuntu"
}

variable "ssh_key_path" {
  description = "Path to the SSH private key that will be used to connect to the VMs"
  default     = "~/.ssh/id_rsa"
}

variable "ssh_proxy_user" {
  description = "Bastion host SSH username"
  default     = ""
}

variable "ssh_proxy_host" {
  description = "Bastion host used to proxy SSH connections"
  default     = ""
}

variable "admin_password" {
  description = "Password override for the initial admin user"
  default     = ""
}

variable "rancher_version" {
  description = "Override for the installed Rancher version."
  default     = ""
}

variable "rancher_image_tag" {
  description = "Override for the installed Rancher image tag."
  default     = ""
}

variable "helm_v3_registry_host" {
  default = ""
}

variable "helm_v3_registry_user" {
  default = ""
}

variable "helm_v3_registry_password" {
  default = ""
}

variable "newrelic_license_key" {
  default = ""
}

variable "require_imdsv2" {
  description = "Require instance metadata service v2"
}
