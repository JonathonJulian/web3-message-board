# vSphere data sources
data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore_nvme" {
  count         = var.datastore_nvme != null ? 1 : 0
  name          = var.datastore_nvme
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore_ssd" {
  count         = var.datastore_ssd != null ? 1 : 0
  name          = var.datastore_ssd
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore_sata" {
  count         = var.datastore_sata != null ? 1 : 0
  name          = var.datastore_sata
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
  datastore_id     = lookup({
    "NVME" = var.datastore_nvme != null ? data.vsphere_datastore.datastore_nvme[0].id : data.vsphere_datastore.datastore.id,
    "SSD"  = var.datastore_ssd != null ? data.vsphere_datastore.datastore_ssd[0].id : data.vsphere_datastore.datastore.id,
    "SATA" = var.datastore_sata != null ? data.vsphere_datastore.datastore_sata[0].id : data.vsphere_datastore.datastore.id
  }, lookup(each.value, "storage_class", "SSD"), data.vsphere_datastore.datastore.id)
  host_system_id   = data.vsphere_host.host.id
  datacenter_id    = data.vsphere_datacenter.datacenter.id
  folder           = var.vm_folder

  # VM hardware settings from vm_configs or fallback to template
  num_cpus             = try(each.value.cpu, var.vm_cpu_override != null ? var.vm_cpu_override : data.vsphere_ovf_vm_template.ubuntu_cloud.num_cpus)
  num_cores_per_socket = 1  # Explicitly set to 1 to prevent drift

  # Memory - Convert from GB to MB (vSphere expects MB)
  # Input memory values are in GB, need to convert to MB
  # Template values are already in MB
  memory               = try(
    each.value.memory != null ? each.value.memory * 1024 : null,
    var.vm_memory_override,
    data.vsphere_ovf_vm_template.ubuntu_cloud.memory
  )

  guest_id             = data.vsphere_ovf_vm_template.ubuntu_cloud.guest_id
  firmware             = data.vsphere_ovf_vm_template.ubuntu_cloud.firmware
  scsi_type            = data.vsphere_ovf_vm_template.ubuntu_cloud.scsi_type

  # Controller settings - Keep minimum required IDE controllers and add SATA
  ide_controller_count = 1  # Minimum required by vSphere validation
  sata_controller_count = 1 # Add SATA for CD-ROM

  # Network interfaces
  dynamic "network_interface" {
    for_each = data.vsphere_ovf_vm_template.ubuntu_cloud.ovf_network_map
    content {
      network_id = network_interface.value
    }
  }

  # Disk configuration
  dynamic "disk" {
    for_each = (try(each.value.disk_size_gb, null) != null || var.default_disk_size_gb != null) ? [1] : []
    content {
      label            = "disk0"
      size             = try(each.value.disk_size_gb, var.default_disk_size_gb)
      eagerly_scrub    = false
      thin_provisioned = true
      unit_number      = 0
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

  # CD-ROM configuration - use SATA controller but keep client_device true
  # This should avoid "Connection control operation failed for disk 'ide1:0'" error
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
          network_type = each.value.network_type
          ip_address   = try(each.value.ip_address, "")
          subnet_mask  = try(each.value.subnet_mask, "24")
          gateway      = var.default_gateway
          dns_servers  = var.dns_servers
          ssh_key      = var.ssh_public_key
        }
      ))
    }
  }

  # Prevent unnecessary replacements and resource churn
  lifecycle {
    ignore_changes = [
      num_cores_per_socket,
      annotation,
      ept_rvi_mode,
      hv_mode,
      guest_id,
      scsi_controller_count,
      scsi_type,
      firmware,
      pci_device_id
    ]
  }
}