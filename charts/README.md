# Web3 Message Board Monitoring Stack

This directory contains Helm charts for deploying the monitoring stack for the Web3 Message Board project.

## Chart Structure

The monitoring stack is split into modular components:

- **minio-storage**: MinIO object storage for Loki and other components
- **loki-stack**: Loki logging system with Grafana for visualization and Prometheus for metrics

## Deployment

### Prerequisites

- Kubernetes cluster with ingress-nginx controller
- kubectl configured with the right context
- Helm v3 installed

### Using the deploy script

The simplest way to deploy all components is to use the provided script:

```bash
./deploy.sh
```

This will automatically:
1. Build all chart dependencies
2. Deploy MinIO first
3. Deploy the Loki stack after MinIO is ready

### Manual Deployment

If you want to deploy components individually:

1. Build and deploy MinIO storage first:
```bash
helm dependency build ./minio-storage
helm upgrade --install minio-storage ./minio-storage --namespace web3
```

2. Build and deploy Loki stack (after MinIO is ready):
```bash
helm dependency build ./loki-stack
helm upgrade --install loki-stack ./loki-stack --namespace web3
```

## Accessing the Services

After deployment, you can access:

- Grafana dashboard: http://grafana.local
- Loki logs: http://loki.local
- MinIO storage: http://minio.local

## Configuration

Each chart has its own `values.yaml` file where you can configure:

- Service-specific settings
- Resources and scaling
- Ingress configuration
- Storage options