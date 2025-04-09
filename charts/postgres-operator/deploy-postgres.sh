#!/bin/bash
set -e

# Parse command-line arguments
TIMEOUT="10m"

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --namespace)
      NAMESPACE="$2"
      shift
      shift
      ;;
    --timeout)
      TIMEOUT="$2"
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Configuration (fallback to defaults if not provided as arguments)
NAMESPACE=${NAMESPACE:-"web3"}
RELEASE_NAME=${RELEASE_NAME:-"postgres-operator"}
CREATE_CLUSTER=${CREATE_CLUSTER:-"true"}
CLUSTER_NAME=${CLUSTER_NAME:-"message-board-db"}

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE > /dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Step 1: Add the Postgres Operator Helm repositories if not already added
echo "Adding Helm repositories for PostgreSQL Operator..."
helm repo list | grep -q "postgres-operator-charts" || helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo list | grep -q "postgres-operator-ui-charts" || helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui
helm repo update

# Step 2: Build dependencies for PostgreSQL Operator
echo "Building dependencies for PostgreSQL Operator..."
helm dependency build .

# Step 3: Deploy PostgreSQL Operator
echo "Deploying PostgreSQL Operator..."
helm upgrade --install ${RELEASE_NAME} . \
  --namespace ${NAMESPACE} \
  --timeout ${TIMEOUT} \
  --set createCluster=${CREATE_CLUSTER} \
  --set clusterName=${CLUSTER_NAME}

# Step 4: Wait for the operator to be ready
echo "Waiting for PostgreSQL Operator pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgres-operator --timeout=120s -n ${NAMESPACE} || echo "PostgreSQL Operator pods not ready yet, continuing..."

# If we're creating a cluster, wait for it to be ready
if [ "$CREATE_CLUSTER" = "true" ]; then
  echo "PostgreSQL cluster will be created. It may take several minutes for all resources to be ready."
  echo "You can check the status with the following command:"
  echo "kubectl get postgresql -n ${NAMESPACE}"
fi

echo "Deployment completed successfully!"
echo ""
echo "You can access the PostgreSQL Operator UI at: http://postgres-ui.local"
echo ""
echo "To get the password for the default admin user:"
echo "kubectl get secret ${CLUSTER_NAME}.message-board-user.credentials -n ${NAMESPACE} -o 'jsonpath={.data.password}' | base64 -d"