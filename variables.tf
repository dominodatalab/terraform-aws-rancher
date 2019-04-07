variable "vpc_id" {
  description = ""
}

variable "subnet_ids" {
  description = ""
  type = "list"
}

variable "key_name" {
  description = ""
}

variable "name" {
  description = ""
  default     = "rancher"
}

variable "instance_count" {
  description = ""
  default     = 3
}

variable "internal_lb" {
  description = ""
  default     = false
}

variable "ami" {
  description = ""
  default     = "ami-0565af6e282977273"
}

variable "instance_type" {
  description = ""
  default     = "t3.xlarge"
}

variable "security_group_ids" {
  description = ""
  default     = []
}

variable "placement_group" {
  description = ""
  default     = ""
}

variable "os_disk_size" {
  description = ""
  default     = 30
}

variable "os_disk_type" {
  description = ""
  default     = "gp2"
}

variable "os_disk_delete_on_termination" {
  description = ""
  default     = true
}

variable "ebs_optimized" {
  description = ""
  default     = true
}

variable "enable_detailed_monitoring" {
  description = ""
  default     = false
}

variable "enable_deletion_protection" {
  description = ""
  default     = false
}

variable "tags" {
  description = ""
  default     = {}
}
