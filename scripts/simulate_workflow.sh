#!/bin/bash
set -e

# Simulate a GitHub workflow for adding a VM called "webserver"

# Set environment variables to match workflow
export IS_TEST_MODE="true"
export TEST_ACTION="add"
export TEST_VM_NAME="webserver"
export TEST_NETWORK_TYPE="static"
export TEST_IP_ADDRESS="192.168.1.201"
export TEST_SUBNET_MASK="24"

# MinIO configuration
export MINIO_ENDPOINT="http://minio.local"
export MINIO_ACCESS_KEY="minioadmin"
export MINIO_SECRET_KEY="minioadmin"
export MINIO_BUCKET="terraform-state"
export MINIO_OBJECT_PATH="vm-configs/terraform.tfvars.json"

echo "=== Simulating GitHub Actions Workflow ==="
echo "Action: ${TEST_ACTION}"
echo "VM Name: ${TEST_VM_NAME}"
echo "Network: ${TEST_NETWORK_TYPE}"
echo "IP: ${TEST_IP_ADDRESS}/${TEST_SUBNET_MASK}"
echo ""

# Step 1: Pull VM configs from MinIO
echo "=== STEP 1: Pull VM configurations from MinIO ==="
# Install MinIO client if needed
if ! command -v mc &> /dev/null; then
    echo "Installing MinIO client..."
    curl -sL https://dl.min.io/client/mc/release/linux-amd64/mc -o /tmp/mc
    chmod +x /tmp/mc
    MC_BIN="/tmp/mc"
else
    MC_BIN="mc"
fi

# Configure MinIO client
echo "Configuring MinIO client..."
$MC_BIN alias set myminio "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --api S3v4

# Create the destination directory
mkdir -p ./terraform/environments/dev

# Check if object exists in MinIO
if $MC_BIN stat myminio/$MINIO_BUCKET/$MINIO_OBJECT_PATH &>/dev/null; then
    echo "Pulling VM configurations from MinIO..."
    $MC_BIN cp myminio/$MINIO_BUCKET/$MINIO_OBJECT_PATH ./terraform/environments/dev/terraform.tfvars.json
    CONFIGS_PULLED=true
else
    echo "No existing VM configurations found in MinIO. Creating a new configuration file."
    echo '{"vm_configs": {}}' > ./terraform/environments/dev/terraform.tfvars.json
    CONFIGS_PULLED=false
fi

# Display the current configurations
echo "Current VM configurations:"
cat ./terraform/environments/dev/terraform.tfvars.json | jq .
echo ""

# Step 2: Run VM management script
echo "=== STEP 2: Run VM management script ==="
# Set parameters
ACTION="$TEST_ACTION"
VM_NAME="$TEST_VM_NAME"
NETWORK_TYPE="$TEST_NETWORK_TYPE"
IP_ADDRESS="$TEST_IP_ADDRESS"
SUBNET_MASK="$TEST_SUBNET_MASK"

echo "Running with: ACTION=$ACTION, VM_NAME=$VM_NAME, NETWORK_TYPE=$NETWORK_TYPE"
if [[ "$NETWORK_TYPE" == "static" ]]; then
    echo "Static IP: $IP_ADDRESS/$SUBNET_MASK"
fi

# Run the script with appropriate parameters
if [[ "$ACTION" == "list" ]]; then
    ./manage_vms.sh list
elif [[ "$ACTION" == "add" && -n "$VM_NAME" ]]; then
    ./manage_vms.sh add "$VM_NAME" "$NETWORK_TYPE" "$IP_ADDRESS" "$SUBNET_MASK"
elif [[ "$ACTION" == "remove" && -n "$VM_NAME" ]]; then
    ./manage_vms.sh remove "$VM_NAME"
elif [[ "$ACTION" == "apply" ]]; then
    ./manage_vms.sh apply
else
    echo "Invalid action or missing required parameters"
    exit 1
fi

# Save VM configurations for next steps
if [[ -f "./terraform/environments/dev/terraform.tfvars.json" ]]; then
    cp ./terraform/environments/dev/terraform.tfvars.json /tmp/vm_configs.json
    CONFIGS_SAVED=true
else
    CONFIGS_SAVED=false
fi
echo ""

# Step 3: Push updated configurations to MinIO
echo "=== STEP 3: Push updated configurations to MinIO ==="
# Run the MinIO push script
./scripts/push_to_minio.sh
echo ""

# Step 4: Apply Terraform configuration (simulate only)
echo "=== STEP 4: Apply Terraform configuration (SIMULATED) ==="
if [[ "$CONFIGS_SAVED" == "true" && ("$ACTION" == "add" || "$ACTION" == "remove" || "$ACTION" == "apply") ]]; then
    echo "Would run:"
    echo "cd ./terraform/environments/dev"
    echo "export TF_VAR_vsphere_user=\"\$VSPHERE_USER\""
    echo "export TF_VAR_vsphere_password=\"\$VSPHERE_PASSWORD\""
    echo "export TF_VAR_vsphere_server=\"\$VSPHERE_SERVER\""
    echo "export AWS_ACCESS_KEY_ID=\"\$MINIO_ACCESS_KEY\""
    echo "export AWS_SECRET_ACCESS_KEY=\"\$MINIO_SECRET_KEY\""
    echo "terraform init"
    echo "terraform apply -auto-approve"
    echo "(Skipping actual Terraform apply for simulation)"
fi
echo ""

# Step 5: Wait for VMs and verify accessibility (simulate only)
echo "=== STEP 5: Wait for VMs and verify accessibility (SIMULATED) ==="
if [[ "$CONFIGS_SAVED" == "true" && ("$ACTION" == "add" || "$ACTION" == "apply") ]]; then
    echo "Would wait for VM to come online and check SSH connectivity"

    # Create a simple simulation status file
    cat > /tmp/vm_status.json <<EOF
[
  {
    "name": "${VM_NAME}",
    "key": "${VM_NAME}",
    "ip": "${IP_ADDRESS}",
    "status": "Online (Simulated)",
    "ssh_status": "Available (Simulated)",
    "ssh_command": "ssh ubuntu@${IP_ADDRESS}"
  }
]
EOF

    echo "VM status:"
    cat /tmp/vm_status.json | jq .
fi
echo ""

# Step 6: Generate summary
echo "=== STEP 6: Generate summary ==="
echo "VM Management Summary"
echo ""
echo "Action Performed"
echo ""
echo "- Mode: TEST"
echo "- Action: $ACTION"

if [[ "$ACTION" == "add" ]]; then
    echo "- VM Added: $VM_NAME"
    echo "- Network Type: $NETWORK_TYPE"
    if [[ "$NETWORK_TYPE" == "static" ]]; then
        echo "- IP Address: $IP_ADDRESS/$SUBNET_MASK"
    fi
fi

echo ""
if [[ -f "/tmp/vm_status.json" ]]; then
    echo "Current VMs"
    echo ""
    echo "| VM Key | Name | IP Address | Status | SSH | Access Command |"
    echo "|--------|------|------------|--------|-----|---------------|"

    # Display VM status in table format
    jq -r '.[] | "| \(.key) | \(.name) | \(.ip) | \(.status) | \(.ssh_status) | \(.ssh_command) |"' /tmp/vm_status.json

    echo ""
    echo "Access Instructions"
    echo ""
    echo "For VMs with SSH available:"
    echo "1. Make sure you have the appropriate SSH key configured"
    echo "2. Use the access command shown in the table above"
fi

echo ""
echo "MinIO Configuration Storage"
echo ""
echo "VM configurations are stored in MinIO at:"
echo "- URL: $MINIO_ENDPOINT/$MINIO_BUCKET/$MINIO_OBJECT_PATH"
echo ""
echo "=== Simulation Complete ==="