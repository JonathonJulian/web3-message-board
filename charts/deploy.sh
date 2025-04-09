#!/bin/bash
set -e

# Configuration
NAMESPACE=${NAMESPACE:-"web3"}
RELEASE_NAME_MINIO=${RELEASE_NAME_MINIO:-"minio-storage"}
RELEASE_NAME_LOKI=${RELEASE_NAME_LOKI:-"loki-stack"}
RELEASE_NAME_PG=${RELEASE_NAME_PG:-"postgres-operator"}
DEPLOY_PG=${DEPLOY_PG:-"false"}

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE > /dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Step 1: Build dependencies for MinIO Storage
echo "Building dependencies for MinIO Storage..."
helm dependency build ./minio-storage

# Step 2: Deploy MinIO Storage (must be deployed first)
echo "Deploying MinIO Storage..."
helm upgrade --install ${RELEASE_NAME_MINIO} ./minio-storage --namespace ${NAMESPACE}

# Wait for MinIO to be ready
echo "Waiting for MinIO pods to be ready..."
kubectl wait --for=condition=ready pod -l app=minio --timeout=120s -n ${NAMESPACE} || echo "MinIO pods not ready yet, continuing..."

# Step 3: Build dependencies for Loki Stack
echo "Building dependencies for Loki Stack..."
helm dependency build ./loki-stack

# Step 4: Deploy Loki Stack
echo "Deploying Loki Stack..."
helm upgrade --install ${RELEASE_NAME_LOKI} ./loki-stack --namespace ${NAMESPACE}

# Step 5: Deploy PostgreSQL Operator if enabled
if [ "$DEPLOY_PG" = "true" ]; then
  echo "Deploying PostgreSQL Operator..."
  cd postgres-operator && ./deploy-postgres.sh
  cd ..
fi

echo "Deployment completed successfully!"
echo ""
echo "You can access the following services:"
echo "- MinIO: http://minio.local"
echo "- Grafana: http://grafana.local"
echo "- Loki: http://loki.local"
if [ "$DEPLOY_PG" = "true" ]; then
  echo "- PostgreSQL Operator UI: http://postgres-ui.local"
fi