#------------------------------------------------------------------------------
# REQUIRED
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC where resources should be created"
  type        = string
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
  type        = string
}

#------------------------------------------------------------------------------
# YOU MUST CHOOSE ONE OF THE FOLLOWING OTHERWISE PROVISIONING WILL FAIL!
#------------------------------------------------------------------------------
variable "use_provisioner_secgrp" {
  description = "Determines whether to use the security provision_security_group or provisioner_cidr_block inputs."
  default     = "true"
  type        = string
}

variable "provisioner_security_group" {
  description = "ID of security group attached to the VM that will provision the Rancher instances. This is typically a bastion host."
  default     = ""
  type        = string
}

variable "provisioner_cidr_block" {
  description = "CIDR address of the host that will provision the Rancher instances. This will only work with instances that are publicly accessible."
  default     = ""
  type        = string
}

#------------------------------------------------------------------------------
# OPTIONAL
#------------------------------------------------------------------------------
variable "name" {
  description = "Root name applied to all resources"
  default     = "rancher"
  type        = string
}

variable "internal_lb" {
  description = "Create an internal load balancer. Defaults to internet-facing."
  default     = false
  type        = string
}

variable "lb_security_groups" {
  description = "Grant LB ingress access to one or more security group IDs"
  default     = []
  type        = list(string)
}

variable "lb_security_groups_count" {
  description = "Count of dynamically determines lb_security_groups"
  default     = 0
  type        = number
}

variable "lb_cidr_blocks" {
  description = "Grant LB ingress access to one or more CIDR addresses"
  default     = []
  type        = list(string)
}

variable "instance_count" {
  description = "Number of instances to launch"
  default     = 3
  type        = number
}

variable "ami" {
  description = "Instance AMI defaults to Ubuntu 24.04"
  default     = "ami-00c257e12d6828491"
  type        = string
}

variable "instance_type" {
  description = "Type of instances to launch"
  default     = "t3.xlarge"
  type        = string
}

variable "os_disk_size" {
  description = "Root partition volume size for instances"
  default     = 30
  type        = number
}

variable "os_disk_type" {
  description = "Root partition volume type for instances"
  default     = "gp3"
  type        = string
}

variable "os_disk_delete_on_termination" {
  description = "Destroy root EBS volume when instances are terminated"
  default     = true
  type        = bool
}

variable "os_disk_encrypted" {
  description = "Encrypt root EBS volume"
  default     = true
  type        = bool
}

variable "os_disk_kms_key_id" {
  description = "Optional encryption key for root EBS volume"
  default     = ""
  type        = string
}

variable "ebs_optimized" {
  description = "Attach NICs dedicated to EBS volume network traffic"
  default     = true
  type        = bool
}

variable "enable_detailed_monitoring" {
  description = "Launch EC2 instances with detailed monitoring enabled"
  default     = false
  type        = bool
}

variable "enable_deletion_protection" {
  description = ""
  default     = false
  type        = bool
}

variable "tags" {
  description = "Extra tags assigned to all resources"
  default     = {}
  type        = map(string)
}

#------------------------------------------------------------------------------
# RANCHHAND
#------------------------------------------------------------------------------
variable "ranchhand_working_dir" {
  description = "Directory where ranchhand should be executed. Defaults to the current working directory."
  default     = ""
  type        = string
}

variable "cert_dnsnames" {
  description = "Hostnames for the rancher and rke ssl certs (comma-delimited)"
  default     = [""]
  type        = list(string)
}

variable "cert_ipaddresses" {
  description = "IP addresses for the rancher and rke ssl certs (comma-delimited)"
  default     = ["127.0.0.1"]
  type        = list(string)
}

variable "ssh_username" {
  description = "SSH username on the nodes"
  default     = "ubuntu"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to the SSH private key that will be used to connect to the VMs"
  default     = "~/.ssh/id_rsa"
  type        = string
}

variable "ssh_proxy_user" {
  description = "Bastion host SSH username"
  default     = ""
  type        = string
}

variable "ssh_proxy_host" {
  description = "Bastion host used to proxy SSH connections"
  default     = ""
  type        = string
}

variable "admin_password" {
  description = "Password override for the initial admin user"
  default     = ""
  type        = string
}

# Update the rancher_* variables together
# Please reference the Rancher support matrix before changing these values
# https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/
# before changing these values
variable "rancher_version" {
  description = "Override for the installed Rancher version. Without the [v]"
  default     = "2.10.5"
  type        = string
}

variable "rancher_image_tag" {
  description = "Override for the installed Rancher image tag. With the [v]"
  default     = "v2.10.5"
  type        = string
}

variable "rancher_kubectl_version" {
  description = "Override for the kubectl version supported by RKE to install. With the [v]"
  default     = "v1.31.5"
  type        = string
}

variable "rancher_rke_version" {
  description = "Override for the installed RKE image tag. With the [v]"
  default     = "v1.7.3"
  type        = string
}

variable "helm_v3_registry_host" {
  default = ""
  type    = string
}

variable "helm_v3_registry_user" {
  default = ""
  type    = string
}

variable "helm_v3_registry_password" {
  default = ""
  type    = string
}

variable "newrelic_license_key" {
  default = ""
  type    = string
}

variable "require_imdsv2" {
  description = "Require instance metadata service v2"
  type        = bool
}
