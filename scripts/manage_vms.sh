#!/bin/bash
set -e

# Default values
ACTION=""
VM_NAME=""
NETWORK_TYPE="dhcp"
IP_ADDRESS=""
SUBNET_MASK="24"
SSH_PUBLIC_KEY=""

# Parse named parameters
while [[ $# -gt 0 ]]; do
  case "$1" in
    --action=*)
      ACTION="${1#*=}"
      shift
      ;;
    --vm-name=*)
      VM_NAME="${1#*=}"
      shift
      ;;
    --network-type=*)
      NETWORK_TYPE="${1#*=}"
      shift
      ;;
    --ip-address=*)
      IP_ADDRESS="${1#*=}"
      shift
      ;;
    --subnet-mask=*)
      SUBNET_MASK="${1#*=}"
      shift
      ;;
    --ssh-public-key=*)
      SSH_PUBLIC_KEY="${1#*=}"
      shift
      ;;
    *)
      # Support legacy positional arguments for backward compatibility
      if [[ -z "$ACTION" ]]; then
        ACTION="$1"
      elif [[ -z "$VM_NAME" ]]; then
        VM_NAME="$1"
      elif [[ -z "$NETWORK_TYPE" ]]; then
        NETWORK_TYPE="$1"
      elif [[ -z "$IP_ADDRESS" ]]; then
        IP_ADDRESS="$1"
      elif [[ -z "$SUBNET_MASK" ]]; then
        SUBNET_MASK="$1"
      elif [[ -z "$SSH_PUBLIC_KEY" ]]; then
        SSH_PUBLIC_KEY="$1"
      fi
      shift
      ;;
  esac
done

# Configuration paths - adjust for scripts directory
CONFIG_DIR="../terraform/environments/dev"
TFVARS_FILE="${CONFIG_DIR}/terraform.tfvars.json"

# Auto-adjust paths if run from project root
if [[ -d "./terraform" && ! -d "../terraform" ]]; then
  CONFIG_DIR="./terraform/environments/dev"
  TFVARS_FILE="${CONFIG_DIR}/terraform.tfvars.json"
fi

# Ensure we have required parameters
if [[ "$ACTION" == "add" && -z "$VM_NAME" ]]; then
  echo "Error: VM_NAME is required for add action"
  echo "Usage: $0 --action=add --vm-name=<name> [--network-type=static|dhcp] [--ip-address=<ip>] [--subnet-mask=<mask>] [--ssh-public-key=<key>]"
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
  local vm_name="$1"
  local network_type="$2"
  local ip_address="$3"
  local subnet_mask="$4"
  local ssh_public_key="$5"

  echo "Adding VM: $vm_name with network type: $network_type"
  if [[ "$network_type" == "static" ]]; then
    echo "Static IP configuration: $ip_address/$subnet_mask"
  fi

  # Ensure configuration file exists
  if [[ ! -f "$TFVARS_FILE" ]]; then
    echo '{"vm_configs":{}}' > "$TFVARS_FILE"
  fi

  # Load existing configurations
  local existing_configs=$(cat "$TFVARS_FILE")

  # Update with new VM config
  local vm_config="{\"name\":\"$vm_name\",\"network_type\":\"$network_type\""
  if [[ "$network_type" == "static" ]]; then
    vm_config="$vm_config,\"ip_address\":\"$ip_address\",\"subnet_mask\":\"$subnet_mask\""
  fi
  if [[ -n "$ssh_public_key" ]]; then
    # Escape the ssh key for JSON
    local escaped_key=$(echo "$ssh_public_key" | sed 's/"/\\"/g')
    vm_config="$vm_config,\"ssh_public_key\":\"$escaped_key\""
  fi
  vm_config="$vm_config}"

  # Replace or add VM configuration
  local vm_key="\"$vm_name\":"
  if echo "$existing_configs" | grep -q "$vm_key"; then
    # Update existing VM
    jq ".vm_configs.$vm_name = $vm_config" "$TFVARS_FILE" > "${TFVARS_FILE}.tmp"
    mv "${TFVARS_FILE}.tmp" "$TFVARS_FILE"
  else
    # Add new VM
    jq ".vm_configs += {\"$vm_name\": $vm_config}" "$TFVARS_FILE" > "${TFVARS_FILE}.tmp"
    mv "${TFVARS_FILE}.tmp" "$TFVARS_FILE"
  fi

  echo "VM configuration added/updated successfully."
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
  terraform init -upgrade
  terraform apply -auto-approve

  echo "Terraform apply completed"
}

# Main command handling
case "$ACTION" in
  add)
    add_vm "$VM_NAME" "$NETWORK_TYPE" "$IP_ADDRESS" "$SUBNET_MASK" "$SSH_PUBLIC_KEY"
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
