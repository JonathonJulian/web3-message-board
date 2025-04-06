# Web3 Message Board Monitoring Stack

This directory contains a Helm chart for deploying the Web3 Message Board monitoring stack, which includes Loki, Promtail, Grafana, and MinIO.

## Architecture Overview

The monitoring stack runs in Kubernetes while the application components (frontend and API) run on virtual machines. This architecture provides:

1. **Separation of Concerns**: Application runs on VMs for simplicity, monitoring runs on Kubernetes for scalability
2. **Centralized Logging**: All application and infrastructure logs flow to the Kubernetes-based Loki
3. **Unified Dashboards**: Grafana provides visualization for both application and infrastructure metrics

![Monitoring Architecture](../docs/monitoring_architecture.png)

## Integration with VM-based Components

The VM-based components integrate with this monitoring stack through:

1. **Promtail Agents**: Installed on VMs via Ansible, they collect and forward logs to Loki
2. **Metrics Exporters**: The API service exposes Prometheus-compatible metrics
3. **Nginx Access Logs**: Frontend server logs are shipped to Loki for user behavior analysis

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- kubectl configured to access your cluster
- VM infrastructure with the application components

## Components

### Loki

Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system. It's designed to be very cost-effective and easy to operate, as it does not index the contents of the logs, but rather a set of labels for each log stream.

### Promtail

Promtail is an agent which ships the contents of local logs to Loki. It is deployed as:
- A DaemonSet in Kubernetes to collect container logs
- A systemd service on VMs (via Ansible) to collect application logs

### Grafana

Grafana is a multi-platform open source analytics and interactive visualization web application. It provides charts, graphs, and alerts for the web when connected to supported data sources.

Key dashboards include:
- Web3 Message Board Application Dashboard
- Blockchain Transaction Monitor
- User Activity Dashboard
- Infrastructure Overview

### MinIO

MinIO is a high-performance, S3-compatible object storage system. In this stack, MinIO is used for persistent storage of logs and metrics data.

## Configuration

The configuration for the monitoring stack is defined in the `values.yaml` file. Key configuration options include:

### Persistent Volume Configuration

The stack uses several persistent volumes for data storage:
- `monitoring-grafana-pv` for Grafana data
- `monitoring-minio-pv` for MinIO storage
- `monitoring-loki-write-pv-50gb` for Loki's write path
- `monitoring-loki-backend-pv-50gb` for Loki's backend storage

These PVs are configured in the `templates/pv.yaml` file.

### Loki Configuration

- Storage configuration for Loki (S3-compatible storage using MinIO)
- Logging limits and retention period
- SimpleScalable deployment mode with persistence
- Ingress configuration

### Grafana Configuration

- Admin user credentials
- Persistence configuration
- Ingress configuration
- Data source configuration for Loki

## Installation

### Automatic Installation with Makefile

Use the provided Makefile commands to install the monitoring stack:

```bash
# Deploy the entire monitoring stack
make monitoring-deploy

# Deploy individual components
make grafana-deploy
make loki-deploy
make minio-deploy
```

These commands will:
1. Create the necessary namespace
2. Update Helm dependencies
3. Install/upgrade the Helm chart
4. Wait for the deployments to be ready

### Manual Installation

1. Update Helm dependencies:
   ```bash
   cd monitoring
   helm dependency update
   ```

2. Install the Helm chart:
   ```bash
   helm upgrade --install monitoring . \
     --namespace web3-message-board \
     --create-namespace \
     --timeout 10m
   ```

## Accessing the Services

### Grafana

Grafana is accessible through its ingress at `/grafana`. If you've configured the ingress with a hostname, you can access it at:

```
http://grafana.local/grafana
```

Alternatively, you can use port forwarding:

```bash
# Using the Makefile
make monitoring-port-forward

# Or directly with kubectl
kubectl port-forward -n web3-message-board svc/monitoring-grafana 3000:80
```

Then access Grafana at http://localhost:3000.

Default credentials:
- Username: admin
- Password: admin

### Loki

Loki is accessible through its ingress at `/loki`. If using the same hostname as Grafana:

```
http://grafana.local/loki
```

You can also use port forwarding:

```bash
kubectl port-forward -n web3-message-board svc/monitoring-loki 3100:3100
```

Then access Loki at http://localhost:3100.

## Using the Monitoring Stack

### Querying Logs from VM Applications

Once configured, logs from the VM-based components will appear in Grafana with the following labels:
- `job`: Either `nginx` or `api` to indicate the source
- `hostname`: The VM's hostname
- `level`: Log level (info, warn, error)

Sample LogQL query for API errors:
```
{job="api"} |= "error" | json | line_format "{{.message}}"
```

### Viewing Application Metrics

Application metrics from the API service are available in Grafana. Key metrics include:
- Message posting rates
- Blockchain transaction success/failure
- Gas usage over time
- User engagement metrics

## Troubleshooting

### Integration Issues

If logs from VMs are not appearing in Loki:

1. Check Promtail status on VMs:
   ```bash
   sudo systemctl status promtail
   ```

2. Verify Promtail configuration:
   ```bash
   sudo cat /etc/promtail/config.yml
   ```

3. Ensure Loki is accessible from the VMs:
   ```bash
   curl http://<kubernetes-ingress-ip>/loki/api/v1/labels
   ```

For other issues, refer to the "Troubleshooting" section in the main README.