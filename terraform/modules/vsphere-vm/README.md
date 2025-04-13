# vSphere VM Module

This Terraform module creates virtual machines in VMware vSphere from an OVF/OVA template.

## Features

- Deploy multiple VMs from a single source template
- Support for both DHCP and static IP configuration
- Highly customizable VM configurations
- Cloud-init based customization
- Automatic SSH key injection
- Ready-to-use Ansible inventory generation

## Usage

```hcl
module "vsphere_vms" {
  source = "path/to/modules/vsphere-vm"

  # vSphere infrastructure
  datacenter = "DC0"
  datastore  = "SSD"
  cluster    = "LabCluster"
  network    = "VM Network"
  host       = "192.168.1.67"
  vm_folder  = "/DevOps-VMs"

  # VM configurations
  vm_configs = {
    "web-server" = {
      name         = "web-server"
      network_type = "static"      # Use "static" or "dhcp"
      ip_address   = "192.168.1.95"
    },
    "db-server" = {
      name         = "db-server"
      network_type = "dhcp"        # DHCP doesn't require ip_address
    }
  }

  # Optional VM hardware overrides
  vm_cpu_override    = 2
  vm_memory_override = 4096

  # Authentication
  ssh_public_key = "ssh-ed25519 AAAAC3Nz...example...X jon@example.com"
}

# Output examples
output "vm_ips" {
  value = module.vsphere_vms.vm_ips
}
```

## Requirements

- vSphere environment with:
  - vCenter Server (with access credentials)
  - ESXi host(s)
  - Network with DHCP (if using DHCP configuration)
  - OVF/OVA template accessible via URL or local path

## Input Variables

### vSphere Connection

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| datacenter | vSphere datacenter name | `string` | - | yes |
| datastore | vSphere datastore name | `string` | - | yes |
| cluster | vSphere cluster name | `string` | - | yes |
| network | vSphere network name | `string` | - | yes |
| host | ESXi host name to deploy on | `string` | - | yes |
| vm_folder | vSphere folder for VMs | `string` | "/DevOps-VMs" | no |

### VM Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vm_configs | Map of VM configurations containing name, network type, and optional static IP settings | `map(object)` | - | yes |
| vm_cpu_override | Override the CPU count from the template | `number` | `null` | no |
| vm_memory_override | Override the memory size from the template (in MB) | `number` | `null` | no |
| ovf_remote_url | URL to the remote OVF/OVA template | `string` | Ubuntu Noble cloud image | no |

### Network Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vm_domain | Domain name for the VMs | `string` | "local" | no |
| default_gateway | Default gateway for static IPs | `string` | "192.168.1.1" | no |
| dns_servers | List of DNS servers | `list(string)` | ["8.8.8.8", "8.8.4.4"] | no |

### Authentication

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ssh_public_key | SSH public key for the ubuntu user | `string` | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| vm_details | Detailed information about each VM (name, ID, IP, power state) |
| vm_ips | Map of VM names to their IP addresses |
| ssh_commands | SSH commands for connecting to the VMs |
| ansible_inventory | Ready-to-use Ansible inventory in INI format |

## Notes

- The module uses cloud-init for guest OS customization
- Static IP assignments will work even if Terraform cannot see the VM's IP address
- For static IPs, DNS records or /etc/hosts entries may need to be manually configured
- Memory specifications in `vm_configs` are in GB (e.g., `memory = 4` means 4GB)
- The `vm_memory_override` value is in MB (e.g., `vm_memory_override = 4096` means 4GB)
- Ubuntu 24.04 (Noble) requires at least 2GB of memory to function properly
- VM disk sizes have a minimum of 20GB to accommodate the Ubuntu 24.04 Noble image
- If you specify a custom disk size in `vm_configs.disk_size_gb`, it must be at least 20GB
- Disk sizes cannot be reduced after a VM is created (VMware limitation)