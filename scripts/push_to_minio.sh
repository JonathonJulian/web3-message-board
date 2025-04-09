#!/bin/bash
set -e

# MinIO connection details - these should be set as environment variables
# or provided as command line arguments
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio.local}"
MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-minioadmin}"
MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-minioadmin}"
MINIO_BUCKET="${MINIO_BUCKET:-terraform-state}"
MINIO_OBJECT_PATH="${MINIO_OBJECT_PATH:-vm-configs/terraform.tfvars.json}"

# Source file to upload - account for the script now being in scripts/
SOURCE_FILE="${3:-../terraform/environments/dev/terraform.tfvars.json}"

# Check if running from project root and adjust path if needed
if [[ -d "./terraform" && ! -d "../terraform" ]]; then
  SOURCE_FILE="${3:-./terraform/environments/dev/terraform.tfvars.json}"
fi

# Check if required tools are installed
if ! command -v mc &> /dev/null; then
    echo "MinIO client (mc) is not installed. Installing..."
    curl -sL https://dl.min.io/client/mc/release/linux-amd64/mc -o /tmp/mc
    chmod +x /tmp/mc
    MC_BIN="/tmp/mc"
else
    MC_BIN="mc"
fi

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file $SOURCE_FILE does not exist"
    exit 1
fi

# Check if required parameters are provided
if [ -z "$MINIO_ACCESS_KEY" ] || [ -z "$MINIO_SECRET_KEY" ]; then
    echo "Error: MinIO access key and secret key are required"
    echo "Usage: $0 <access_key> <secret_key> [source_file] [bucket] [object_path]"
    exit 1
fi

echo "Configuring MinIO client..."
$MC_BIN alias set myminio "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" --api S3v4

# Check if the bucket exists, create if it doesn't
if ! $MC_BIN ls myminio/$MINIO_BUCKET &> /dev/null; then
    echo "Bucket $MINIO_BUCKET does not exist, creating..."
    $MC_BIN mb myminio/$MINIO_BUCKET
fi

echo "Pushing $SOURCE_FILE to MinIO at $MINIO_BUCKET/$MINIO_OBJECT_PATH..."
$MC_BIN cp "$SOURCE_FILE" "myminio/$MINIO_BUCKET/$MINIO_OBJECT_PATH"

echo "File successfully uploaded to MinIO"
echo "URL: $MINIO_ENDPOINT/$MINIO_BUCKET/$MINIO_OBJECT_PATH"

# Cleanup if we installed mc temporarily
if [ "$MC_BIN" = "/tmp/mc" ]; then
    rm -f /tmp/mc
fi