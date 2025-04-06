# Terraform vSphere VM Provisioning

This Terraform configuration creates an Ubuntu VM in your vSphere environment using an Ubuntu Cloud Image OVA.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
2. Access to a vSphere/vCenter environment
3. Ubuntu Cloud Image OVA file (ubuntu-cloud.ova)
4. SSH key pair for VM access

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your environment-specific values:
   - vCenter credentials
   - vSphere infrastructure details (datacenter, datastore, cluster, network)
   - VM configuration (CPU, memory, disk)
   - Network configuration (IP, gateway, etc.)
   - Your SSH public key

## Deployment

### Using the Makefile

To deploy using the project Makefile (from the root directory):

```bash
make vm-create
```

### Manual Deployment

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Deploy the VM with Terraform:
   ```bash
   terraform apply
   ```

3. The Ubuntu Cloud Image will automatically configure itself using cloud-init
4. SSH access will be available once the VM boots and cloud-init completes

## After Installation

After the VM is up and running:

```bash
./update_inventory.sh
```

This updates the Ansible inventory with the VM details.

## Using the VM with Ansible

Run the Ansible playbook to configure the server:
```bash
cd ../ansible
make ansible-deploy
```

Or using the Makefile from the project root:
```bash
make ansible-deploy
```

## Access the Web Interface

After Ansible deployment, access the web interface at:
```
http://<VM-IP-ADDRESS>
```

## Cleanup

To remove the VM using the Makefile:
```bash
make vm-delete
```

Or manually:
```bash
terraform destroy
```

## Troubleshooting

### VM Connection Issues

If you're unable to connect to the VM:
1. Check the VM status using the Makefile:
   ```bash
   make vm-status
   ```

2. Verify that the VM has completed cloud-init initialization:
   ```bash
   ssh ubuntu@<VM-IP> 'cloud-init status'
   ```

3. Check the network configuration:
   ```bash
   ssh ubuntu@<VM-IP> 'ip addr show'
   ```

## Notes

- The VM is configured with cloud-init to set up SSH and basic networking
- Default username is 'ubuntu'
- SSH key authentication is automatically configured
- Cloud-init will update packages and install basic software during first boot