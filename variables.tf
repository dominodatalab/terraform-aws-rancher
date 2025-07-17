#------------------------------------------------------------------------------
# REQUIRED
#------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC where resources should be created"
  type        = string
}

variable "server_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 3
  validation {
    condition     = var.server_count >= 3
    error_message = "server_count must be at least 3 to ensure high availability."
  }
}

variable "rke2_server_url" {
  description = "RKE2 server URL used to join nodes to the cluster"
  type        = string
}

# Check CNI and versions at https://docs.rke2.io/release-notes/v{K8S_VER}.X
# i.e. https://docs.rke2.io/release-notes/v1.32.X
variable "cni_plugin" {
  description = "CNI plugin to use for the RKE2 cluster (canal, calico, cilium, flannel)"
  default     = "calico"
  type        = string

  validation {
    condition = alltrue([
      for mode in var.cni_plugin : contains(["canal", "calico", "cilium", "flannel"], mode)
    ])
    error_message = "cni_plugin must be one of 'canal', 'calico', 'cilium', or 'flannel'."
  }
}

variable "node_taint" {
  description = "Taint to apply to the RKE2 nodes (e.g., 'node-role.kubernetes.io/control-plane:NoSchedule')"
  default     = ""
  type        = string
}

variable "server_instance_type" {
  description = "Instance type for the RKE2 server nodes"
  default     = "t3.xlarge"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair to use for the instances"
  default     = "rke2-keypair"
  type        = string

}

variable "subnet_ids" {
  description = "List of subnet IDs where the RKE2 server nodes will be created"
  type        = list(string)

}

variable "node_os_version" {
  description = "Operating system version for the RKE2 nodes (e.g., 'ubuntu-24.04')"
  default     = "ubuntu-24.04"
  type        = string
}

variable "rke2_version" {
  description = "Override for the installed RKE2 version. With the 'v'"
  type        = string
  default     = "v1.32.4+rke2r1"

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+\\+rke2r[0-9]+$", var.rke2_version))
    error_message = "rke2_version must be in the format v<MAJOR>.<MINOR>.<PATCH>+rke2r<REVISION>, e.g., v1.32.4+rke2r1"
  }
}

variable "rke2_token" {
  description = "Token for RKE2 cluster"
  type        = string
  sensitive   = true
}

variable "cluster_dns" {
  description = "Cluster DNS IP"
  type        = string
  default     = "10.43.0.10"
  validation {
    condition     = provider::assert::ip(var.ip_address)
    error_message = "Invalid cluster_dns address"
  }
}

variable "cluster_domain" {
  description = "Cluster domain"
  type        = string
  default     = "cluster.local"
}

variable "cluster_cidr" {
  description = "IPv4/IPv6 network CIDRs to use for pod IPs"
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = provider::assert::cidr(var.cluster_cidr)
    error_message = "Invalid cluster_cidr"
  }
}

variable "service_cidr" {
  description = "IPv4/IPv6 network CIDRs to use for service IPs"
  type        = string
  default     = "10.43.0.0/16"

  validation {
    condition     = provider::assert::cidr(var.service_cidr)
    error_message = "Invalid service_cidr"
  }
}

variable "enable_detailed_monitoring" {
  description = "Launch EC2 instances with detailed monitoring enabled"
  default     = false
  type        = bool
}

variable "enable_deletion_protection" {
  description = "If true, enables EC2 Instance Termination Protection"
  default     = false
  type        = bool
}

variable "os_disk_size" {
  description = "Root partition volume size for instances"
  default     = 30
  type        = number
}

variable "os_disk_type" {
  description = "Root partition volume type for instances (io1, io2, gp2, gp3, sc1, st1, standard)"
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

variable "tags" {
  description = "Extra tags assigned to all resources"
  default     = {}
  type        = map(string)
}

# #------------------------------------------------------------------------------
# # OPTIONAL
# #------------------------------------------------------------------------------
variable "name" {
  description = "Root name applied to all resources"
  default     = "rancher"
  type        = string
}

variable "ami" {
  description = "Specific AMI ID to use for the RKE2 nodes. If not specified, the latest Ubuntu AMI will be used."
  type        = string
  validation {
    condition     = can(regex("^ami-[a-z0-9]+$", var.ami)) || var.ami == ""
    error_message = "AMI must be a valid AMI ID or an empty string to use the default Ubuntu AMI."
  }
}

variable "egress_selector_mode" {
  description = "RKE2 egress selector mode (agent, cluster, pod, disabled)"
  default     = "agent"
  type        = string
  validation {
    # condition = contains(["agent", "cluster", "pod", "disabled"], var.egress_selector_mode)
    # condition = var.egress_selector_mode == "agent" || var.egress_selector_mode == "cluster" || var.egress_selector_mode == "pod" || var.egress_selector_mode == "disabled"
    condition = alltrue([
      for mode in var.egress_selector_mode : contains(["agent", "cluster", "pod", "disabled"], mode)
    ])
    error_message = "egress_selector_mode must be one of 'agent', 'cluster', 'pod', or 'disabled'."
  }
}



# variable "ebs_optimized" {
#   description = "Attach NICs dedicated to EBS volume network traffic"
#   default     = true
#   type        = bool
# }




# #------------------------------------------------------------------------------
# # RKE2 CONFIGURATION
# #------------------------------------------------------------------------------

# variable "cert_dnsnames" {
#   description = "Hostnames for the rancher and RKE2 ssl certs (comma-delimited)"
#   default     = [""]
#   type        = list(string)
# }

# variable "cert_ipaddresses" {
#   description = "IP addresses for the rancher and RKE2 ssl certs (comma-delimited)"
#   default     = ["127.0.0.1"]
#   type        = list(string)
# }

# variable "ssh_username" {
#   description = "SSH username on the nodes"
#   default     = "ubuntu"
#   type        = string
# }

# variable "ssh_key_path" {
#   description = "Path to the SSH private key that will be used to connect to the VMs"
#   default     = "~/.ssh/id_rsa"
#   type        = string
# }

# variable "ssh_proxy_user" {
#   description = "Bastion host SSH username"
#   default     = ""
#   type        = string
# }

# variable "ssh_proxy_host" {
#   description = "Bastion host used to proxy SSH connections"
#   default     = ""
#   type        = string
# }

# variable "admin_password" {
#   description = "Password override for the initial admin user"
#   default     = ""
#   type        = string
# }

# # Update the rancher_* and rke2_* variables together
# # Please reference the Rancher support matrix before changing these values
# # https://www.suse.com/suse-rancher/support-matrix/all-supported-versions/
# variable "rancher_version" {
#   description = "Override for the installed Rancher version. Without the [v]"
#   default     = "2.10.5"
#   type        = string
# }

# variable "rancher_image_tag" {
#   description = "Override for the installed Rancher image tag. With the [v]"
#   default     = "v2.10.5"
#   type        = string
# }

# variable "rancher_kubectl_version" {
#   description = "Override for the kubectl version supported by RKE2 to install. With the [v]"
#   default     = "v1.31.5"
#   type        = string
# }

# variable "rke2_version" {
#   description = "Override for the installed RKE2 version. With the [v]"
#   default     = "v1.31.5+rke2r1"
#   type        = string
# }

# variable "rke2_channel" {
#   description = "RKE2 release channel (stable, latest)"
#   default     = "stable"
#   type        = string
# }

# variable "rke2_cni" {
#   description = "RKE2 CNI plugin (canal, calico, cilium)"
#   default     = "canal"
#   type        = string
# }

# variable "rke2_disable_cloud_controller" {
#   description = "Disable RKE2 cloud controller manager"
#   default     = false
#   type        = bool
# }

# variable "rke2_config_file" {
#   description = "Path to custom RKE2 configuration file"
#   default     = ""
#   type        = string
# }

# variable "helm_v3_registry_host" {
#   default = ""
#   type    = string
# }

# variable "helm_v3_registry_user" {
#   default = ""
#   type    = string
# }

# variable "helm_v3_registry_password" {
#   default = ""
#   type    = string
# }

# variable "newrelic_license_key" {
#   default = ""
#   type    = string
# }
