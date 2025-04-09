# vSphere data sources
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
  name          = var.host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# Load OVF template from URL
data "vsphere_ovf_vm_template" "ubuntu_cloud" {
  name              = "ubuntu-cloud-template"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  remote_ovf_url    = var.ovf_remote_url
  ovf_network_map = {
    "VM Network" : data.vsphere_network.network.id
  }
  allow_unverified_ssl_cert = true
}

# Create one VM for each entry in the vm_configs map
resource "vsphere_virtual_machine" "vm" {
  for_each = var.vm_configs

  name             = each.value.name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  datacenter_id    = data.vsphere_datacenter.datacenter.id
  folder           = var.vm_folder

  # VM hardware settings from template or overrides
  num_cpus             = var.vm_cpu_override != null ? var.vm_cpu_override : data.vsphere_ovf_vm_template.ubuntu_cloud.num_cpus
  num_cores_per_socket = data.vsphere_ovf_vm_template.ubuntu_cloud.num_cores_per_socket
  memory               = var.vm_memory_override != null ? var.vm_memory_override : data.vsphere_ovf_vm_template.ubuntu_cloud.memory
  guest_id             = data.vsphere_ovf_vm_template.ubuntu_cloud.guest_id
  firmware             = data.vsphere_ovf_vm_template.ubuntu_cloud.firmware
  scsi_type            = data.vsphere_ovf_vm_template.ubuntu_cloud.scsi_type

  # Network interfaces
  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.ubuntu_cloud.ovf_network_map
    content {
      network_id = network_interface.value
    }
  }

  # Wait timeouts
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  wait_for_guest_ip_timeout  = var.wait_for_guest_ip_timeout

  # OVF deployment
  ovf_deploy {
    remote_ovf_url            = data.vsphere_ovf_vm_template.ubuntu_cloud.remote_ovf_url
    disk_provisioning         = data.vsphere_ovf_vm_template.ubuntu_cloud.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.ubuntu_cloud.ovf_network_map
    allow_unverified_ssl_cert = true
  }

  # CD-ROM for vApp properties
  cdrom {
    client_device = true
  }

  # vApp properties for cloud-init configuration
  vapp {
    properties = {
      "hostname"    = each.value.name
      "instance-id" = each.value.name
      "public-keys" = var.ssh_public_key
      "user-data"   = base64encode(templatefile(
        "${path.module}/templates/cloud-init.tftpl",
        {
          hostname     = each.value.name
          domain       = var.vm_domain
          ssh_key      = var.ssh_public_key
          network_type = lookup(each.value, "network_type", "dhcp")
          ip_address   = lookup(each.value, "ip_address", null)
          subnet_mask  = lookup(each.value, "subnet_mask", "24")
          gateway      = var.default_gateway
          dns_servers  = var.dns_servers
        }
      ))
    }
  }

  lifecycle {
    ignore_changes = [
      vapp[0].properties,
    ]
  }
}