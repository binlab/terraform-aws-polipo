variable "ami_vendor" {
  description = "OS Vandor AMI [coreos/flatcar]"
  type        = string
  default     = "flatcar"
}

variable "ami_channel" {
  description = "OS Vandor AMI [stable/edge/beta/etc]"
  type        = string
  default     = "stable"
}

variable "docker_image" {
  description = "Docker Image Name with Tag"
  type        = string
  default     = "binlab/polipo:1.1.1"
}

variable "instance_type" {
  description = "Type of instance e.g. [t3.small]"
  type        = string
  default     = "t3.small"
}

variable "monitoring" {
  description = "CloudWatch Detailed Monitoring [true/false]"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Root Block Device Volume Size (GB) e.g. [8]"
  type        = number
  default     = 8
}

variable "volume_type" {
  description = "Root Block Device Volume Type e.g. [gp2]"
  type        = string
  default     = "gp2"
}

variable "delete_on_termination" {
  description = "Root Block Device - Delete On Termination [true/false]"
  type        = bool
  default     = true
}

variable "cpu_credits" {
  description = "The Credit Option for CPU Usage [unlimited/standard]"
  type        = string
  default     = "standard"
}

variable "vps_security_group_ids" {
  description = "List of VPS Security Group IDs"
  type        = list(string)
}

variable "vps_subnet_id" {
  description = "VPS Subnet ID"
  type        = string
}

variable "key_name" {
  description = "AWS SSH Key Name"
  type        = string
}

variable "root_ssh_public_key" {
  description = "Root SSH Public Key to 'core' User"
  type        = string
}

variable "ca_ssh_public_key" {
  description = "Certificate Authority SSH Public Key"
  type        = string
}

variable "tags" {
  description = "Map of Tags"
  type        = map(string)
  default = {
    Description = "Polipo Proxy"
    ManagedBy   = "Terraform"
    Name        = "Polipo"
  }
}

variable "proxy_port" {
  description = "Proxy Port Number"
  type        = number
  default     = 8123
}

variable "allowed_cidr" {
  description = "List of Allowed Client CIDRs e.g. [192.168.1.0/24, 192.168.5.10]"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "proxy_user" {
  description = "HTTP Basic Authentication - Proxy Username"
  type        = string
}

variable "proxy_pass" {
  description = "HTTP Basic Authentication - Proxy Password"
  type        = string
}
