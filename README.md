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

### Pre-commit Hooks

To enable pre-commit hooks for automatic linting:

```bash
git config core.hooksPath .githooks
```

The pre-commit hook will run appropriate linters based on the files you're committing.

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
