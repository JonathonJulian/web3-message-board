module "vsphere_vms" {
  source     = "./modules/vsphere-vm"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  cluster    = var.vsphere_cluster
  network    = var.vsphere_network
  host       = var.vsphere_host

  vm_folder  = var.vsphere_vm_folder
  vm_domain  = var.vm_domain

  # Use VM configurations from terraform.tfvars.json
  vm_configs = var.vm_configs

  # Use SSH public key from environment or variable
  ssh_public_key = var.ssh_public_key

  # Add the runner's SSH key for Ansible access
  additional_ssh_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHQTZgYpm0K6DX25sgOpE1fE4jS9iPwedZudRXZEEQc4 runner@vm"
  ]
}