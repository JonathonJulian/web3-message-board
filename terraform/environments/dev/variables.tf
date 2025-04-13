# vSphere connection details
variable "vsphere_user" {
  description = "vSphere user name"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
  default     = "192.168.1.100"
}

# vSphere infrastructure details
variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
  default     = "DC0"
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
  default     = "SSD"
}

variable "datastore_nvme" {
  description = "vSphere NVME datastore name"
  type        = string
  default     = "NVME"
}

variable "datastore_ssd" {
  description = "vSphere SSD datastore name"
  type        = string
  default     = "SSD"
}

variable "datastore_sata" {
  description = "vSphere SATA datastore name"
  type        = string
  default     = "SATA"
}

variable "cluster" {
  description = "vSphere cluster name"
  type        = string
  default     = "LabCluster"
}

variable "network" {
  description = "vSphere network name"
  type        = string
  default     = "VM Network"
}

variable "host" {
  description = "ESXi host name to deploy on"
  type        = string
  default     = "192.168.1.67"
}

variable "vm_folder" {
  description = "vSphere folder for VMs"
  type        = string
  default     = "/DevOps-VMs"
}

# Network settings
variable "vm_domain" {
  description = "Domain name for the VMs"
  type        = string
  default     = "local"
}

variable "default_gateway" {
  description = "Default gateway for static IPs"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# Authentication
variable "ssh_public_key" {
  description = "SSH public key for the ubuntu user"
  type        = string
}

# Default hardware settings
variable "default_disk_size_gb" {
  description = "Default disk size in GB for VMs that don't specify it"
  type        = number
  default     = 20
}