#!/bin/bash
set -e

# Default values
ACTION=""
VM_NAME=""
NETWORK_TYPE="dhcp"
IP_ADDRESS=""
SUBNET_MASK="24"
SSH_PUBLIC_KEY=""
DISK_SIZE_GB=""
CPU=""
MEMORY=""

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
    --disk-size-gb=*)
      DISK_SIZE_GB="${1#*=}"
      shift
      ;;
    --cpu=*)
      CPU="${1#*=}"
      shift
      ;;
    --memory=*)
      MEMORY="${1#*=}"
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
  local disk_size_gb="$6"
  local cpu="$7"
  local memory="$8"

  echo "Adding VM: $vm_name with network type: $network_type"
  if [[ "$network_type" == "static" ]]; then
    echo "Static IP configuration: $ip_address/$subnet_mask"
  fi
  if [[ -n "$disk_size_gb" ]]; then
    echo "Disk size: ${disk_size_gb}GB"
  fi
  if [[ -n "$cpu" ]]; then
    echo "CPU cores: $cpu"
  fi
  if [[ -n "$memory" ]]; then
    echo "Memory: ${memory}MB"
  fi

  # Ensure configuration file exists
  if [[ ! -f "$TFVARS_FILE" ]]; then
    echo '{"vm_configs":{}}' > "$TFVARS_FILE"
  fi

  # Create a temporary file for the operation
  TEMP_FILE="$(mktemp)"

  # Prepare VM configuration with all parameters
  jq -n \
    --arg name "$vm_name" \
    --arg type "$network_type" \
    '{
      "name": $name,
      "network_type": $type
    }' > "$TEMP_FILE"

  # Add static network configuration if needed
  if [[ "$network_type" == "static" ]]; then
    jq --arg ip "$ip_address" \
       --arg mask "$subnet_mask" \
       '. += {"ip_address": $ip, "subnet_mask": $mask}' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
  fi

  # Add SSH key if provided
  if [[ -n "$ssh_public_key" ]]; then
    jq --arg key "$ssh_public_key" \
       '. += {"ssh_public_key": $key}' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
  fi

  # Add hardware specs if provided
  if [[ -n "$disk_size_gb" ]]; then
    jq --argjson size "$disk_size_gb" \
       '. += {"disk_size_gb": $size}' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
  fi

  if [[ -n "$cpu" ]]; then
    jq --argjson cpu_val "$cpu" \
       '. += {"cpu": $cpu_val}' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
  fi

  if [[ -n "$memory" ]]; then
    jq --argjson mem_val "$memory" \
       '. += {"memory": $mem_val}' "$TEMP_FILE" > "${TEMP_FILE}.tmp" && mv "${TEMP_FILE}.tmp" "$TEMP_FILE"
  fi

  # Get the final VM config JSON
  VM_CONFIG=$(cat "$TEMP_FILE")

  # Add or update the VM in the config file
  if jq -e --arg name "$vm_name" '.vm_configs | has($name)' "$TFVARS_FILE" > /dev/null; then
    # Update existing VM
    jq --arg name "$vm_name" \
       --argjson config "$VM_CONFIG" \
       '.vm_configs[$name] = $config' "$TFVARS_FILE" > "${TFVARS_FILE}.tmp" && mv "${TFVARS_FILE}.tmp" "$TFVARS_FILE"
  else
    # Add new VM
    jq --arg name "$vm_name" \
       --argjson config "$VM_CONFIG" \
       '.vm_configs[$name] = $config' "$TFVARS_FILE" > "${TFVARS_FILE}.tmp" && mv "${TFVARS_FILE}.tmp" "$TFVARS_FILE"
  fi

  # Clean up temp file
  rm -f "$TEMP_FILE"

  echo "VM configuration added/updated successfully."
}

# List all configured VMs
function list_vms() {
  vm_configs=$(get_vm_configs)
  echo "Current VM configurations:"
  echo "$vm_configs" | jq -r 'to_entries | .[] | "\(.key):\n  name: \(.value.name)\n  network: \(.value.network_type) \(if .value.network_type == "static" then "(\(.value.ip_address)/\(.value.subnet_mask))" else "" end)\(if .value.disk_size_gb then "\n  disk size: \(.value.disk_size_gb)GB" else "" end)\(if .value.cpu then "\n  cpu: \(.value.cpu) cores" else "" end)\(if .value.memory then "\n  memory: \(.value.memory)MB" else "" end)"'
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
    add_vm "$VM_NAME" "$NETWORK_TYPE" "$IP_ADDRESS" "$SUBNET_MASK" "$SSH_PUBLIC_KEY" "$DISK_SIZE_GB" "$CPU" "$MEMORY"
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
    echo "Options:"
    echo "  --action=<action>           - Action to perform (add, list, remove, apply)"
    echo "  --vm-name=<name>            - VM name"
    echo "  --network-type=<type>       - Network type (static or dhcp)"
    echo "  --ip-address=<ip>           - IP address for static networking"
    echo "  --subnet-mask=<mask>        - Subnet mask for static networking"
    echo "  --ssh-public-key=<key>      - SSH public key for VM access"
    echo "  --disk-size-gb=<size>       - Disk size in GB (e.g., 20)"
    echo "  --cpu=<cores>               - Number of CPU cores (e.g., 2)"
    echo "  --memory=<MB>               - Memory in MB (e.g., 4096)"
    echo ""
    echo "Examples:"
    echo "  $0 add web-server-3 static 192.168.1.97 24"
    echo "  $0 add db-server-1 dhcp --disk-size-gb=40 --cpu=4 --memory=8192"
    echo "  $0 --action=add --vm-name=web-server-3 --network-type=static --ip-address=192.168.1.97 --disk-size-gb=30"
    echo "  $0 list"
    echo "  $0 remove web-server-1"
    ;;
esac
