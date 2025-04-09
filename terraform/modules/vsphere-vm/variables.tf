# vSphere connection variables
variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster name"
  type        = string
}

variable "network" {
  description = "vSphere network name"
  type        = string
}

variable "host" {
  description = "ESXi host name to deploy on"
  type        = string
}

variable "vm_folder" {
  description = "vSphere folder for VMs"
  type        = string
  default     = "/DevOps-VMs"
}

# OVF template variables
variable "ovf_remote_url" {
  description = "URL to the remote OVF/OVA template"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.ova"
}

# VM configuration
variable "vm_configs" {
  description = "Map of VM configurations containing name, network type, and optional static IP settings"
  type = map(object({
    name         = string
    network_type = optional(string, "dhcp")
    ip_address   = optional(string)
    subnet_mask  = optional(string, "24")
  }))

  validation {
    condition = alltrue([
      for vm in var.vm_configs :
        vm.network_type == "dhcp" ||
        (vm.network_type == "static" && vm.ip_address != null)
    ])
    error_message = "When network_type is 'static', ip_address must be provided."
  }
}

variable "vm_cpu_override" {
  description = "Override the CPU count from the template (null = use template setting)"
  type        = number
  default     = null
}

variable "vm_memory_override" {
  description = "Override the memory size in MB from the template (null = use template setting)"
  type        = number
  default     = null
}

variable "wait_for_guest_net_timeout" {
  description = "Timeout for waiting for guest network (0 = disabled)"
  type        = number
  default     = 5
}

variable "wait_for_guest_ip_timeout" {
  description = "Timeout for waiting for guest IP address (0 = disabled)"
  type        = number
  default     = 5
}

# Network configuration
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