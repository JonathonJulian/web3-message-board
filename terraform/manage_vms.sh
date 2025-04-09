#!/bin/bash
set -e

# Command arguments
ACTION="${1:-help}"
VM_NAME="${2:-}"
NETWORK_TYPE="${3:-dhcp}"
IP_ADDRESS="${4:-}"
SUBNET_MASK="${5:-24}"

# Configuration paths
CONFIG_DIR="./environments/dev"
TFVARS_FILE="${CONFIG_DIR}/terraform.tfvars.json"

# Ensure we have required parameters
if [[ "$ACTION" == "add" && -z "$VM_NAME" ]]; then
  echo "Error: VM_NAME is required for add action"
  echo "Usage: $0 add <vm_name> [network_type] [ip_address] [subnet_mask]"
  exit 1
fi

if [[ "$NETWORK_TYPE" == "static" && -z "$IP_ADDRESS" ]]; then
  echo "Error: IP_ADDRESS is required when network_type is static"
  exit 1
fi

# Function to read existing configs or initialize new one
function get_vm_configs() {
  if [[ -f "$TFVARS_FILE" ]]; then
    VM_CONFIGS=$(jq -r '.vm_configs // {}' "$TFVARS_FILE")
  else
    VM_CONFIGS="{}"
  fi
  echo "$VM_CONFIGS"
}

# Function to update vm_configs in tfvars
function update_vm_configs() {
  local vm_configs="$1"
  
  # Create or update terraform.tfvars.json
  if [[ -f "$TFVARS_FILE" ]]; then
    # Update existing file
    jq --arg configs "$vm_configs" '.vm_configs = ($configs | fromjson)' "$TFVARS_FILE" > "${TFVARS_FILE}.tmp"
    mv "${TFVARS_FILE}.tmp" "$TFVARS_FILE"
  else
    # Create new tfvars file
    echo "{\"vm_configs\": $vm_configs}" > "$TFVARS_FILE"
  fi
  
  echo "Updated VM configurations in $TFVARS_FILE"
}

# Add a new VM configuration
function add_vm() {
  local vm_key="$1"
  local vm_name="$2"
  local network_type="$3"
  local ip_address="$4"
  local subnet_mask="$5"
  
  # Get existing configurations
  local vm_configs=$(get_vm_configs)
  
  # Create new VM config
  if [[ "$network_type" == "static" ]]; then
    new_vm=$(jq -n \
      --arg name "$vm_name" \
      --arg network_type "$network_type" \
      --arg ip_address "$ip_address" \
      --arg subnet_mask "$subnet_mask" \
      '{
        "name": $name,
        "network_type": $network_type,
        "ip_address": $ip_address,
        "subnet_mask": $subnet_mask
      }')
  else
    new_vm=$(jq -n \
      --arg name "$vm_name" \
      --arg network_type "$network_type" \
      '{
        "name": $name,
        "network_type": $network_type
      }')
  fi
  
  # Add the new VM to the configurations
  updated_configs=$(echo "$vm_configs" | jq --arg key "$vm_key" --argjson vm "$new_vm" '. + {($key): $vm}')
  
  # Update the tfvars file
  update_vm_configs "$updated_configs"
  
  echo "Added VM '$vm_key' to configurations"
}

# List all configured VMs
function list_vms() {
  vm_configs=$(get_vm_configs)
  echo "Current VM configurations:"
  echo "$vm_configs" | jq -r 'to_entries | .[] | "\(.key):\n  name: \(.value.name)\n  network: \(.value.network_type) \(if .value.network_type == "static" then "(\(.value.ip_address)/\(.value.subnet_mask))" else "" end)"'
}

# Remove a VM configuration
function remove_vm() {
  local vm_key="$1"
  
  # Get existing configurations
  local vm_configs=$(get_vm_configs)
  
  # Check if VM exists
  if ! echo "$vm_configs" | jq -e --arg key "$vm_key" 'has($key)' > /dev/null; then
    echo "Error: VM '$vm_key' not found in configurations"
    exit 1
  fi
  
  # Remove the VM
  updated_configs=$(echo "$vm_configs" | jq --arg key "$vm_key" 'del(.[$key])')
  
  # Update the tfvars file
  update_vm_configs "$updated_configs"
  
  echo "Removed VM '$vm_key' from configurations"
}

# Apply the Terraform configuration
function apply_config() {
  echo "Applying Terraform configuration..."
  
  cd "$CONFIG_DIR" || exit 1
  terraform init
  terraform apply -auto-approve
  
  echo "Terraform apply completed"
}

# Main command handling
case "$ACTION" in
  add)
    add_vm "$VM_NAME" "$VM_NAME" "$NETWORK_TYPE" "$IP_ADDRESS" "$SUBNET_MASK"
    ;;
  list)
    list_vms
    ;;
  remove)
    remove_vm "$VM_NAME"
    ;;
  apply)
    apply_config
    ;;
  help|*)
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  add <vm_name> [network_type] [ip_address] [subnet_mask] - Add a new VM"
    echo "  list                                                    - List configured VMs"
    echo "  remove <vm_name>                                        - Remove a VM configuration"
    echo "  apply                                                   - Apply Terraform configuration"
    echo ""
    echo "Examples:"
    echo "  $0 add web-server-3 static 192.168.1.97 24"
    echo "  $0 add db-server-1 dhcp"
    echo "  $0 list"
    echo "  $0 remove web-server-1"
    ;;
esac
