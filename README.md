# Web3 Message Board

A decentralized message board application using blockchain technology for secure, transparent, and immutable messaging.

## Overview

Web3 Message Board is a full-stack dApp that combines:

- **Configuration Management**: Ansible for automated deployment and configuration
- **Smart Contracts**: Solidity contracts deployed on EVM-compatible chains
- **Web Frontend**: Responsive UI built with Svelte and Tailwind CSS
- **API Backend**: Go-based service for blockchain interaction
- **Monitoring**: Grafana/Loki for logging and performance monitoring with support for both Promtail and Alloy agents
- **DevOps**: Complete CI/CD pipelines, infrastructure as code, and automated tests

Users can post messages to the blockchain, view the message history, and create profiles - all without a centralized database. Messages are permanently stored on-chain, ensuring transparency and immutability.

## Features

- **On-chain Messaging**: Post and retrieve messages stored directly on the blockchain
- **Web3 Wallet Integration**: Connect with MetaMask or other Web3 wallets
- **User Profiles**: Create and manage blockchain-linked profiles
- **Multi-chain Support**: Deploy and use on various EVM-compatible chains
- **Responsive Design**: Works on both desktop and mobile devices
- **Load Tested**: Performance optimized and verified with Artillery
- **Comprehensive Security**: Firewall, fail2ban, SSH hardening, and more

## Security Features

The application implements multiple layers of security:

- **Firewall Protection**: UFW with strict rules limiting exposure
- **Brute-Force Protection**: fail2ban monitors for suspicious access attempts
- **System Hardening**: Kernel parameters configured for security
- **SSH Hardening**: Disables root login, requires key-based authentication
- **Filesystem Security**: Proper permissions and sticky bits for sensitive directories
- **Automatic Updates**: Unattended security updates for OS packages
- **Security Headers**: XSS protection, content security policy, and frame protection

## Quick Start

The project uses a Makefile to orchestrate operations:

```bash
# Set up the complete infrastructure
make setup-all

# Deploy monitoring stack
make monitoring-deploy

# Run Ansible deployment
make ansible-deploy

# Run the test suite
make test

# View service logs
make logs
```

## Available Make Commands

The project includes numerous make targets to simplify development and operations:

### Development Setup
- `make install-deps` - Install all project dependencies

### Smart Contracts
- `make contracts-test` - Run contract test suite
- `make contracts-deploy` - Deploy contracts to the specified network

### Infrastructure Management
- `make vm-create` - Provision VMs using Terraform
- `make vm-delete` - Destroy VMs
- `make vm-status` - Check VM status

### Kubernetes/Monitoring
- `make monitoring-deploy` - Deploy monitoring stack (Grafana, Loki, MinIO)
- `make monitoring-delete` - Remove monitoring stack
- `make monitoring-logs` - View logs from monitoring components
- `make monitoring-port-forward` - Set up port forwarding for services
- `make grafana-deploy` - Deploy only Grafana
- `make loki-deploy` - Deploy only Loki
- `make minio-deploy` - Deploy only MinIO

### Ansible Configuration
- `make ansible-deploy` - Run complete Ansible playbook
- `make ansible-deploy-ssh` - Run Ansible with explicit SSH key authentication
- `make ansible-deploy-password` - Run Ansible with password authentication
- `make ansible-nginx` - Configure only Nginx
- `make ansible-static_site` - Deploy only the frontend
- `make ansible-api` - Deploy only the API service
- `make ansible-logging` - Configure only logging components
- `make ansible-security` - Configure only security components (firewall, SSH, fail2ban)

### Testing
- `make test` - Run all tests
- `make test-frontend` - Run only frontend tests
- `make test-api` - Run only API tests
- `make test-contracts` - Run only contract tests
- `make test-e2e` - Run end-to-end tests
- `make load-test` - Run performance tests with Artillery

### Utilities
- `make logs` - View logs from deployed services
- `make get-endpoints` - Display service access URLs

For more details, run `make help` to see all available commands.

## Components

### Ansible Infrastructure

The `/ansible` directory contains playbooks and roles for automated deployment:

- **Main Playbook**: `msg_board.yaml` orchestrates the entire application deployment
- **Key Roles**:
  - `nginx`: Configures web server with proper routing
  - `service`: Manages systemd services for the API and frontend
  - `hosts`: Configures /etc/hosts for proper name resolution
  - `logging`: Sets up Promtail agents for log collection
  - `static_site`: Deploys the frontend assets
  - `users`: Manages application users and permissions
  - `firewall`: Configures secure firewall rules
  - `web_security`: Implements system-level security hardening measures
  - `github_cli`: Sets up GitHub CLI for automated deployments
  - `api`: Deploys and configures the blockchain API service

**Infrastructure Components**:
- **Terraform**: VM and cloud resource provisioning in `terraform/` directory
- **Ansible**: Server configuration and application deployment in `ansible/` directory
- **Kubernetes**: Monitoring stack deployment with Helm charts in `monitoring/` directory

Execute the Ansible playbook:
```bash
# Using the Makefile (recommended)
make ansible-deploy

# Or manually
cd ansible
ansible-playbook -i inventory.ini msg_board.yaml
```

**Authentication Options**:
```bash
# SSH key authentication
make ansible-deploy-ssh SSH_KEY_FILE=/path/to/key

# Password authentication
make ansible-deploy-password SSH_PASSWORD=your_password
```

### Smart Contracts

The `/contracts` directory contains Solidity smart contracts:
- `MessageBoard.sol`: Core contract for storing and retrieving messages
- Tests and deployment scripts

Deploy to a testnet:
```bash
# Using the Makefile
make contracts-deploy NETWORK=sepolia

# Or manually
cd contracts
forge script script/DeployMessageBoard.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

### Frontend

The `/frontend` directory contains a Svelte-based web application:
- Connect wallet and display user information
- Post new messages to the blockchain
- View message history from the blockchain

Run locally:
```bash
cd frontend
npm install
npm run dev
```

### API

The `/api` directory contains a Go-based backend service:
- Blockchain interaction for better user experience
- Message indexing for efficient retrieval
- Transaction status tracking
- Gas price estimation

Run locally:
```bash
cd api
go run cmd/main.go
```

## Architecture

The application uses a hybrid architecture:
- **Application Components** (Frontend, API) run on VMs managed by Ansible
- **Monitoring Stack** (Grafana, Loki) runs on Kubernetes for scalability

This design provides simplicity for the application while enabling robust monitoring.

### Logging System

The project includes a flexible logging system with support for:

- **Multiple Agents**: Support for both Promtail and the newer Grafana Alloy agent
- **Automatic Migration**: Tools to migrate configuration from Promtail to Alloy
- **Centralized Storage**: All logs are sent to Loki for centralized storage and querying
- **Log Rotation**: Configured logrotate for proper log management
- **Visual Dashboards**: Pre-configured Grafana dashboards for log visualization

## Development

### Prerequisites

- Node.js 18+
- Go 1.21+
- Foundry (for smart contract development)
- Docker and Kubernetes (for monitoring)

### Testing

The project includes comprehensive testing:
- Smart contract tests with Forge
- API tests with Go's testing package
- Frontend component tests
- E2E tests for complete application flow
- Load tests with Artillery

Run tests:
```bash
make test
```

### CI/CD Pipelines

GitHub Actions workflows for:
- Contract testing and deployment
- Frontend build and testing
- API build and testing
- Infrastructure validation
- Load testing

## Deployment

The application can be deployed to:
1. **Local Environment**: For development
2. **Staging Environment**: For testing
3. **Production Environment**: For end users

Follow the deployment guide in the documentation.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please open an issue on the GitHub repository.

## Docker Support

This project includes Docker support for both the frontend and backend components. We provide:

1. Multi-architecture builds (amd64, arm64)
2. CI/CD pipeline for building and publishing Docker images
3. Development environment using Docker Compose

### Building Docker Images

To build the Docker images locally:

```bash
# Build the frontend image
cd frontend
docker build -t web3-message-board-frontend:latest .

# Build the API image
cd ../api
docker build -t web3-message-board-api:latest .
```

### Multi-Architecture Builds

The GitHub Actions workflow automatically builds images for multiple architectures:

- linux/amd64 (Intel/AMD)
- linux/arm64 (Apple Silicon, ARM-based servers)

You can also build multi-architecture images locally using Docker Buildx:

```bash
# Set up a new builder with multi-architecture support
docker buildx create --name mybuilder --use

# Build and push frontend image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/yourusername/web3-message-board-frontend:latest \
  --push ./frontend

# Build and push API image
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/yourusername/web3-message-board-api:latest \
  --push ./api
```

### Using Makefile Commands

The project includes Makefile commands for Docker operations:

```bash
# Build all Docker images
make docker-build-all

# Build multi-architecture images
make docker-build-multiarch

# Start development environment using Docker Compose
make docker-compose-up
```

## Release System

The project uses semantic versioning with conventional commits:
- `feat:` for new features (minor version bump)
- `fix:` for bug fixes (patch version bump)
- `breaking:` for breaking changes (major version bump)

The release system now consolidates all component builds into a single GitHub release.

## Components

- **API**: Backend service
- **Frontend**: User interface
- **Smart Contracts**: Blockchain integration

## Code Quality

### Linting

This project uses various linters to maintain code quality:

- **YAML**: yamllint for GitHub workflows
- **JavaScript/TypeScript**: ESLint for frontend code
- **Go**: golangci-lint for API code

To set up all linters, run:

```bash
make setup-linters
```

To run all linters:

```bash
make lint
```

For specific components:

```bash
make lint-yaml  # YAML files
make lint-js    # JavaScript/TypeScript
make lint-go    # Go code
```

## Linting Tools

This repository contains several tools to automatically fix linting issues:

### GitHub Actions Workflow Fixes

- **Fix workflow shell scripts**: `./tools/fix_workflow_shell_scripts.sh`
- Fixes shell script syntax, variable quoting, and other common issues in GitHub Actions workflow files

### Ansible File Fixes

- **Fix Ansible linting issues**: `./tools/fix_ansible_linting.sh`
- Addresses empty lines, braces spacing, and indentation issues in Ansible YAML files

### Helm Chart Fixes

- **Fix Helm chart linting issues**: `./tools/fix_helm_linting.sh`
- Fixes common YAML linting issues in Helm charts (empty lines, braces spacing, trailing spaces)
- See `tools/helm-linting/README.md` for details on manual fixes needed for complex template files

## Usage

To fix all linting issues at once:

```bash
make fix-all
```

To fix specific issues:

```bash
make fix-workflows  # Fix GitHub Actions workflow issues
make fix-ansible    # Fix Ansible file issues
make fix-helm       # Fix Helm chart issues
```

To check if fixes were successful:

```bash
make lint-yaml      # Run YAML linting on all files
```

## Project Structure

- `.github/workflows/`: GitHub Actions workflow files
- `ansible/`: Ansible playbooks and roles
- `monitoring/`: Helm charts for monitoring stack
- `terraform/`: Terraform for provisioning VMs on vSphere

# vSphere VM Deployment Automation

This repository contains a Terraform module and automation scripts for deploying and managing VMs in a VMware vSphere environment.

## Features

- Declarative VM deployment with Terraform
- Both static IP and DHCP network configurations
- Cloud-init for guest OS customization
- SSH key injection
- GitHub Actions workflows for automated VM management

## Directory Structure

```
├── terraform/
│   ├── modules/
│   │   └── vsphere-vm/          # Core Terraform module
│   │       ├── main.tf          # Main module code
│   │       ├── variables.tf     # Module variables
│   │       ├── outputs.tf       # Module outputs
│   │       ├── versions.tf      # Provider requirements
│   │       └── templates/       # Cloud-init templates
│   └── environments/
│       └── dev/                 # Development environment
│           ├── main.tf          # Module implementation
│           └── terraform.tfvars.json  # VM configurations
├── .github/
│   └── workflows/
│       ├── manage-vms.yml       # GitHub Actions workflow
│       └── test.env             # Test environment template
└── manage_vms.sh                # VM management script
```

## VM Management Script

The `manage_vms.sh` script provides a simple CLI for managing VMs:

```bash
# Add a VM with static IP
./manage_vms.sh add web-server-3 static 192.168.1.97 24

# Add a VM with DHCP
./manage_vms.sh add db-server-1 dhcp

# List configured VMs
./manage_vms.sh list

# Remove a VM
./manage_vms.sh remove web-server-1

# Apply configuration (create/update VMs)
./manage_vms.sh apply
```

## GitHub Actions Workflow

The GitHub Actions workflow automates VM management through a centralized interface.

### Testing on Non-Default Branches

When testing on non-default branches (anything other than main/master), the workflow will use repository variables instead of workflow inputs.

#### Setting Up Repository Variables

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Select the "Variables" tab
4. Add the following variables:

| Name | Description | Example Value |
|------|-------------|--------------|
| TEST_ACTION | Action to perform (add, remove, list, apply) | add |
| TEST_VM_NAME | VM name to create/manage | test-runner-1 |
| TEST_NETWORK_TYPE | Network type (static or dhcp) | static |
| TEST_IP_ADDRESS | IP address for static IP | 192.168.1.100 |
| TEST_SUBNET_MASK | Subnet mask in CIDR notation | 24 |

#### Setting Up Required Secrets

For both production and testing environments, you need to set up the following secrets:

| Name | Description |
|------|-------------|
| VSPHERE_SERVER | vSphere server URL |
| VSPHERE_USER | vSphere username |
| VSPHERE_PASSWORD | vSphere password |

### Running the Workflow

1. For testing (non-default branches):
   - Set the repository variables as described above
   - Run the workflow - it will use the repository variables automatically

2. For production (main/master branch):
   - The workflow will prompt for inputs when manually triggered
   - Fill in the requested information in the workflow run form

## Terraform Module Usage

The Terraform module can be used directly in your own Terraform configurations:

```hcl
module "vsphere_vms" {
  source = "../../modules/vsphere-vm"

  datacenter     = "Your-Datacenter"
  datastore      = "Your-Datastore"
  cluster        = "Your-Cluster"
  host           = "Your-Host"
  network        = "Your-Network"
  vm_folder      = "Your-Folder"

  ssh_public_key = "ssh-rsa AAAA... your-key"
  default_gateway = "192.168.1.1"
  dns_servers     = ["8.8.8.8", "8.8.4.4"]

  vm_configs = {
    "web-server-1" = {
      name         = "web-server-1"
      network_type = "static"
      ip_address   = "192.168.1.95"
    },
    "db-server-1" = {
      name         = "db-server-1"
      network_type = "dhcp"
    }
  }
}
```

## PostgreSQL Operator

The project supports using the Zalando PostgreSQL Operator for managing PostgreSQL clusters in Kubernetes. This provides several benefits:

- High availability with automated failover
- Backups and point-in-time recovery
- Resource management and scaling
- Credentials management through Kubernetes secrets

### Deploying PostgreSQL Operator

To deploy the PostgreSQL Operator:

```bash
# Deploy the PostgreSQL Operator with UI and a PostgreSQL cluster
make postgres-deploy

# Deploy only the PostgreSQL Operator UI
make postgres-ui-deploy

# Deploy only a PostgreSQL cluster
make postgres-cluster-deploy

# Delete PostgreSQL Operator and clusters
make postgres-delete

# View logs from PostgreSQL Operator and clusters
make postgres-logs

# Get the password for the default database user
make postgres-password
```

### Connecting to PostgreSQL Clusters

When deploying the API in Kubernetes with the PostgreSQL Operator, the database connection details are:

- Host: `<cluster-name>.<namespace>.svc.cluster.local`
- Port: `5432`
- Database: `message_board`
- User: `message_board_user`
- Password: Retrieved from Kubernetes secret

For example, to get the password:

```bash
kubectl get secret message-board-db.message-board-user.credentials -n web3 -o 'jsonpath={.data.password}' | base64 -d
```

### PostgreSQL Operator UI

The PostgreSQL Operator includes a web UI for managing PostgreSQL clusters. Access it at:

```
http://postgres-ui.local
```

## Logging Systems

The project supports multiple logging systems for performance comparison:

### Loki

[Loki](https://grafana.com/oss/loki/) is the default logging system, providing:
- Label-based log indexing
- Integration with Grafana for querying
- Efficient log storage with low resource usage

### Victoria Logs

[Victoria Logs](https://victoriametrics.com/products/victoria-logs/) is an alternative high-performance logging system:
- SQL-like query language for logs
- High ingest rates with low resource consumption
- Label-based indexing compatible with Loki

### Deploying Logging Systems

To deploy and compare the logging systems:

```bash
# Deploy Loki (default)
make charts-deploy

# Deploy Victoria Logs
make victoria-logs-deploy

# View Loki logs
make loki-logs

# View Victoria Logs
make victoria-logs-logs

# Compare performance metrics
make logging-comparison

# Delete Victoria Logs
make victoria-logs-delete
```

### Comparing Logging Systems

Both systems have their strengths:

- **Loki**: Lower memory footprint, better Grafana integration
- **Victoria Logs**: Higher ingest rates, SQL-like querying, better compression

The `make logging-comparison` command provides metrics to compare their performance in your environment.
