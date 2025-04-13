terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.11.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# Configure AWS provider for S3 backend (MinIO)
provider "aws" {
  # These credentials will be supplied via environment variables:
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

  # Settings for MinIO compatibility
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # MinIO endpoint
  endpoints {
    s3 = "http://minio.local"
  }

  # Required field but not used for MinIO
  region = "us-east-1"
}

module "vsphere_vms" {
  source = "../../modules/vsphere-vm"

  # vSphere infrastructure
  datacenter = var.datacenter
  datastore  = var.datastore
  datastore_nvme = var.datastore_nvme
  datastore_ssd = var.datastore_ssd
  datastore_sata = var.datastore_sata
  cluster    = var.cluster
  network    = var.network
  host       = var.host
  vm_folder  = var.vm_folder

  # VM configurations - loaded from terraform.tfvars.json
  vm_configs = var.vm_configs

  # Optional VM hardware overrides
  vm_cpu_override    = 2
  vm_memory_override = 4096
  default_disk_size_gb = var.default_disk_size_gb

  # Network settings
  vm_domain      = var.vm_domain
  default_gateway = var.default_gateway
  dns_servers    = var.dns_servers

  # Authentication
  ssh_public_key = var.ssh_public_key
}

# Output the results for easy reference
output "vm_ips" {
  description = "IP addresses of created VMs"
  value       = module.vsphere_vms.vm_ips
}

output "ssh_commands" {
  description = "SSH commands to connect to the VMs"
  value       = module.vsphere_vms.ssh_commands
}

# Define variables that can be set in terraform.tfvars.json
variable "vm_configs" {
  description = "Map of VM configurations"
  type = map(object({
    name         = string
    network_type = string
    ip_address   = optional(string)
    subnet_mask  = optional(string)
    cpu          = optional(number)
    memory       = optional(number)
    disk_size_gb = optional(number)
    storage_class = optional(string)
  }))
  default = {}
}
