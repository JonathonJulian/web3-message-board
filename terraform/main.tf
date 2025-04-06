terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "~> 2.5.1"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
  client_debug         = true
  client_debug_path    = "./vsphere-debug.log"
  client_debug_path_run = "./vsphere-debug-run.log"
}

provider "aws" {
  region                   = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check  = true
  skip_requesting_account_id = true
  endpoints {
    s3 = "http://localhost:9000"
  }
  s3_use_path_style = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = var.esxi_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


# Create cloud-init user-data with careful formatting
resource "local_file" "user_data" {
  content = <<-EOT
#cloud-config
hostname: ${var.vm_name}
fqdn: ${var.vm_name}.${var.vm_domain}
manage_etc_hosts: true
ssh_pwauth: false

# Explicitly set datasource and disable cloud-init network configuration
# so our settings take precedence
datasource_list: [OVF, NoCloud, None]
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: false
      addresses:
        - ${var.vm_ip}/${var.vm_netmask}
      routes:
        - to: default
          via: ${var.vm_gateway}
      nameservers:
        addresses: ${jsonencode(var.dns_servers)}

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    # Default password is 'ubuntu'
    passwd: $6$rounds=4096$byY7nrwrTW$KxCgIpT9g8JR89tE49RR6NJ5S0iPxAP31mBMJfIvP4EZDw8blNP7n8L9MRwTpW39SQAxxmQm3WCk1E9qyIqKL1
    ssh_authorized_keys:
      - ${var.ssh_public_key}

# Force cloud-init to use our configuration
write_files:
  - path: /etc/cloud/cloud.cfg.d/99-custom-networking.cfg
    owner: root:root
    permissions: '0644'
    content: |
      network:
        config: disabled

package_update: true
package_upgrade: true
packages:
  - python3
  - openssh-server
EOT
  filename = "${path.module}/user-data.yaml"
}

# Create a separate network config file
resource "local_file" "network_config" {
  content = <<-EOT
version: 2
ethernets:
  ens192:
    dhcp4: false
    addresses:
      - ${var.vm_ip}/${var.vm_netmask}
    routes:
      - to: default
        via: ${var.vm_gateway}
    nameservers:
      addresses: ${jsonencode(var.dns_servers)}
EOT
  filename = "${path.module}/network-config.yaml"
}

# Import VM from OVA directly
resource "vsphere_virtual_machine" "ubuntu_server" {
  for_each          = var.vm_configs
  name              = each.value.name
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id
  datacenter_id     = data.vsphere_datacenter.datacenter.id
  folder            = "/DevOps-VMs"
  host_system_id    = data.vsphere_host.host.id

  num_cpus = var.vm_cpu
  memory   = var.vm_memory
  guest_id = "ubuntu64Guest"

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  # Disable VMware Tools network configuration
  extra_config = {
    "guestinfo.route.0"    = "false"
    "guestinfo.dns"       = "false"
    "guestinfo.dnsdomain" = "false"
    "guestinfo.netmask"   = "false"
    "guestinfo.gateway"   = "false"
    "guestinfo.hostname"  = "false"
    "guestinfo.iptables"  = "false"
  }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = var.vm_disk_size
    thin_provisioned = true
  }

  # Add a client CDROM device for cloud-init vApp properties
  cdrom {
    client_device = true
  }

  # Deploy directly from OVA
  ovf_deploy {
    local_ovf_path    = var.ova_file_path
    disk_provisioning = "thin"
    ovf_network_map = {
      "VM Network" = data.vsphere_network.network.id
    }
  }

  # Configure cloud-init through vApp properties
  vapp {
    properties = {
      "hostname"    = each.value.name
      "instance-id" = each.value.name
      "user-data"   = base64encode(<<-EOT
#cloud-config
hostname: ${each.value.name}
fqdn: ${each.value.name}.${var.vm_domain}
manage_etc_hosts: true
ssh_pwauth: false

# Network configuration at the top level directly
network:
  version: 2
  ethernets:
    ens192:
      dhcp4: false
      addresses:
        - ${each.value.ip}/${var.vm_netmask}
      routes:
        - to: default
          via: ${var.vm_gateway}
      nameservers:
        addresses: ${jsonencode(var.dns_servers)}

# Configure VMware tools to NOT manage the network
vmware_tools_config:
  network:
    enabled: false

# Set datasource priority - make OVF very high priority
datasource:
  OVF:
    transport: vmware
    apply_network_config: true

# Ensure datasource list has correct priority
datasource_list: [OVF, None]

# Ensure network module runs first
cloud_config_modules:
  - mounts
  - locale
  - set-passwords
  - network
  - runcmd
  - write_files
  - update_etc_hosts
  - users-groups

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$rounds=4096$byY7nrwrTW$KxCgIpT9g8JR89tE49RR6NJ5S0iPxAP31mBMJfIvP4EZDw8blNP7n8L9MRwTpW39SQAxxmQm3WCk1E9qyIqKL1
    ssh_authorized_keys:
      - ${var.ssh_public_key}

# Disable any other system from managing the network
write_files:
  - path: /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
    content: |
      network:
        config: disabled

  # Additional config to ensure vmware tools doesn't manage network
  - path: /etc/vmware-tools/tools.conf
    content: |
      [guestinfo]
      primary-nics=ens192
      [guestops]
      disable-dnd=true
      disable-vmxcustomization=true

      [network]
      manage-by-ovf=false
      management-interface=false
EOT
      )
      "public-keys" = var.ssh_public_key
    }
  }

  provisioner "local-exec" {
    command = "echo 'Cloud image VM ${each.value.name} created with IP ${each.value.ip}. Cloud-init will configure the VM automatically.'"
  }
}

# Update outputs for the new map structure
output "vm_details" {
  value = {
    for k, vm in vsphere_virtual_machine.ubuntu_server : k => {
      name = vm.name
      ip   = var.vm_configs[k].ip
    }
  }
}

output "ssh_commands" {
  value = {
    for k, vm in vsphere_virtual_machine.ubuntu_server : k => "ssh ubuntu@${var.vm_configs[k].ip}"
  }
}

output "web_urls" {
  value = {
    for k, vm in vsphere_virtual_machine.ubuntu_server : k => "http://${var.vm_configs[k].ip}"
  }
}

output "ansible_inventory" {
  value = <<EOT
[servers]
%{for k, vm in vsphere_virtual_machine.ubuntu_server~}
${vm.name} ansible_host=${var.vm_configs[k].ip} ansible_user=ubuntu
%{endfor~}
EOT
}
