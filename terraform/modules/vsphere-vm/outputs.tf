output "vm_details" {
  description = "Details of the created VMs"
  value = {
    for k, vm in vsphere_virtual_machine.vm : k => {
      name        = vm.name
      id          = vm.id
      ip_address  = vm.default_ip_address
      power_state = vm.power_state
    }
  }
}

output "vm_ips" {
  description = "Map of VM names to their IP addresses"
  value = {
    for k, vm in vsphere_virtual_machine.vm : k =>
      coalesce(
        vm.default_ip_address,
        try(var.vm_configs[k].network_type == "static" ? var.vm_configs[k].ip_address : "", "")
      )
  }
}

output "ssh_commands" {
  description = "SSH commands for connecting to each VM"
  value = {
    for k, vm in vsphere_virtual_machine.vm : k =>
      "ssh ubuntu@${coalesce(
        vm.default_ip_address,
        try(var.vm_configs[k].network_type == "static" ? var.vm_configs[k].ip_address : "", "")
      )}"
  }
}
