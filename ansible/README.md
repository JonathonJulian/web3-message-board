# Ansible Deployment

This folder contains Ansible playbooks and configuration for deploying the Web3 Message Board application.

# Web3 Message Board - Ansible Deployment

This Ansible playbook automates the deployment and configuration of the Web3 Message Board application infrastructure, including web servers, blockchain API services, monitoring, and security.

## Requirements

- Ansible 2.9+
- Target Ubuntu 24.04 server
- SSH access to the target server (key-based or password authentication)
- Ansible control node with SSH key pair

## Roles and Components

The Ansible configuration includes the following key roles:

- **nginx**: Installs and configures Nginx as a reverse proxy for the frontend and API
- **service**: Manages systemd services for application components
- **hosts**: Configures /etc/hosts for proper name resolution
- **logging**: Sets up log collection and management with support for both Promtail and the newer Grafana Alloy agent, including automatic migration between them
- **static_site**: Deploys the Svelte-based frontend application
- **users**: Creates and manages application users with appropriate permissions
- **firewall**: Configures UFW to secure the server (HTTP/HTTPS/SSH)
- **web_security**: Implements system-level security measures including fail2ban, kernel hardening, filesystem security, and SSH configuration
- **github_cli**: Sets up GitHub CLI for automated deployments and updates
- **api**: Deploys the Go-based API service for blockchain interaction

## Directory Structure

```
ansible/
├── inventory.ini     # Define your target servers here
├── msg_board.yaml    # Main playbook
├── requirements.yaml # Ansible Galaxy requirements
├── vars/             # Variable definitions
└── roles/            # Role-based tasks
    ├── nginx/        # Web server configuration
    ├── firewall/     # Security rules
    ├── logging/      # Log collection with Promtail
    ├── api/          # API deployment
    ├── service/      # Systemd service management
    ├── static_site/  # Frontend deployment
    ├── hosts/        # Host configuration
    ├── web_security/ # System-level security hardening
    ├── github_cli/   # GitHub integration
    └── users/        # User management
```

## Authentication Options

The playbook supports multiple authentication methods:

### SSH Key Authentication (Recommended)
```bash
# Using the Makefile
make ansible-deploy-ssh SSH_KEY_FILE=/path/to/private_key

# Directly with Ansible
ansible-playbook -i inventory.ini msg_board.yaml --private-key=/path/to/private_key
```

### Password Authentication
```bash
# Using the Makefile
make ansible-deploy-password SSH_PASSWORD=your_password

# Directly with Ansible
ansible-playbook -i inventory.ini msg_board.yaml --ask-pass
```

## Usage with Makefile

The project's Makefile includes various targets for Ansible operations:

```bash
# Deploy everything
make ansible-deploy

# Deploy specific components
make ansible-nginx      # Deploy and configure Nginx
make ansible-webapp     # Deploy frontend application
make ansible-logging    # Configure logging
make ansible-api        # Deploy API service
```

## Manual Execution

You can also run the playbook directly:

```bash
# Deploy everything
ansible-playbook msg_board.yaml -i inventory.ini

# Deploy specific components (with tags)
ansible-playbook msg_board.yaml -i inventory.ini --tags nginx,api
```

## Variables and Customization

Edit `vars/main.yml` to customize:
- Server hostnames and IP addresses
- Nginx configuration (ports, etc.)
- Blockchain endpoints and wallet configurations
- Monitoring settings (Loki URL)
- User credentials and SSH keys

## Role-Specific Configuration

Each role has its own defaults that can be overridden:

- **nginx/defaults/main.yml**: Web server settings
- **api/defaults/main.yml**: API service parameters including blockchain endpoints
- **logging/defaults/main.yml**: Log collection configuration
- **firewall/defaults/main.yml**: Security rules and allowed ports

## Blockchain API Configuration

The API role installs and configures the Go service that interacts with blockchain networks. Key variables include:

- `api_rpc_endpoint`: Primary blockchain RPC endpoint
- `api_contract_address`: Deployed message board contract address
- `api_chain_id`: Target blockchain network ID

## Logging Configuration

The logging role supports both Promtail and the newer Grafana Alloy agent:

- **Automatic Detection**: The system detects which agent is already installed
- **Migration Support**: Can automatically migrate from Promtail to Alloy with configuration conversion
- **Flexible Configuration**: Supports custom configuration for both agents
- **Diagnostics**: Can generate migration reports to help troubleshoot issues

Key variables for logging configuration:
- `logging_agent`: Set to either "promtail" or "alloy" (defaults to "alloy")
- `loki_url`: URL for Loki log storage server
- `migrate_bypass_errors`: Set to true to bypass errors during migration (defaults to false)
- `migrate_generate_report`: Set to true to generate a migration report (defaults to true)

## Troubleshooting

- If deployment fails, check the verbose logs with `make ansible-deploy-verbose`
- For connectivity issues, verify server accessibility with `ansible -i inventory.ini all -m ping`
- Check log files on the target server: `/var/log/nginx/error.log` and `/var/log/syslog`

## Security Notes

- The playbook includes comprehensive security measures through the web_security role:
  - System hardening with secure kernel parameters
  - Fail2ban for brute-force protection
  - SSH configuration hardening
  - Filesystem security and permissions
  - Automatic security updates
- Nginx is configured with security headers and custom error pages
- Use environment variables or secure credential management for sensitive data
- Always use specific versions in `requirements.yaml` to ensure reproducible deployments
- Consider using SSH keys with passphrase for improved security
