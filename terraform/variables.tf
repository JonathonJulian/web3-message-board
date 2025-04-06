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
  description = "vSphere server"
  type        = string
  default     = "192.168.1.100"
}

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

variable "esxi_host" {
  description = "ESXi host to deploy VM on"
  type        = string
}

variable "network" {
  description = "vSphere network name"
  type        = string
}

variable "iso_datastore" {
  description = "Datastore where ISO file is located"
  type        = string
  default     = "SATA"
}

variable "iso_path" {
  description = "Path to the ISO file within the datastore"
  type        = string
  default     = "iso/ubuntu-22.04.2-live-server-amd64 (1).iso"
}

variable "local_iso_path" {
  description = "Path to a local ISO file to upload (leave empty to use existing ISO)"
  type        = string
  default     = ""
}

variable "vm_folder" {
  description = "VM folder name"
  type        = string
  default     = "DevOps-VMs"
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "web-server-nginx-cloud-3"
}

variable "vm_cpu" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 40
}

variable "vm_domain" {
  description = "VM domain name"
  type        = string
  default     = "local"
}

variable "vm_ip" {
  description = "VM IP address"
  type        = string
  default     = "192.168.1.200"
}

variable "vm_netmask" {
  description = "VM network netmask"
  type        = number
  default     = 24
}

variable "vm_gateway" {
  description = "VM default gateway"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ssh_public_key" {
  description = "SSH public key for the ubuntu user"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO3sOFB9wGEcOgNO5BfxF35Sh+EAOxWTZjx//DK4XHAx jon@blocknative.com"
}

variable "ova_file_path" {
  description = "Path to the OVA file on local system"
  type        = string
  default     = "./ubuntu-cloud.ova"
}

variable "ova_destination" {
  description = "Destination path in the datastore for OVA file"
  type        = string
  default     = "templates/ubuntu-server.ova"
}

variable "vm_configs" {
  description = "Map of VM configurations containing name and IP for each VM"
  type = map(object({
    name = string
    ip   = string
  }))
  default = {
    "vm1" = {
      name = "web-server-nginx-cloud-3"  # keeping existing default name
      ip   = "192.168.1.200"            # keeping existing default IP
    }
  }
}