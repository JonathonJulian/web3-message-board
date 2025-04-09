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
RELEASE_NAME=${RELEASE_NAME:-"victoria-logs"}

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE > /dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Deploy Victoria Logs
echo "Deploying Victoria Logs..."
helm upgrade --install ${RELEASE_NAME} . \
  --namespace ${NAMESPACE} \
  --timeout ${TIMEOUT}

# Wait for Victoria Logs to be ready
echo "Waiting for Victoria Logs pods to be ready..."
kubectl wait --for=condition=ready pod -l app=${RELEASE_NAME}-victoria-logs --timeout=120s -n ${NAMESPACE} || echo "Victoria Logs pods not ready yet, continuing..."

echo "Deployment completed successfully!"
echo ""
echo "You can access Victoria Logs at: http://victoria-logs.local"
echo ""
echo "To view logs, use the Victoria Logs UI or query the API directly:"
echo "curl 'http://victoria-logs.local/select/logsql' -d 'query=SELECT * FROM logs LIMIT 10'"