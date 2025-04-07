# GitHub Actions Runner Dependencies

This Ansible role installs and configures all dependencies needed for GitHub Actions workflow jobs.

## Features

- Installs common system dependencies (make, git, curl, etc.)
- Installs and configures Go, Node.js, and pnpm
- Installs GitHub CLI
- Installs Ansible and common Ansible dependencies
- Automatically installs project-specific dependencies from:
  - `ansible/requirements.yaml` (Ansible collections)
  - `ansible/requirements.txt` (Python packages)

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project_root` | Current directory | Root directory of the project |
| `go_version` | "1.23" | Go version to install |
| `go_install_dir` | "/usr/local/go" | Directory to install Go |
| `node_version` | "20" | Node.js version to install |
| `pnpm_version` | "8" | pnpm version to install |
| `install_go` | true | Whether to install Go |
| `install_node` | true | Whether to install Node.js |
| `install_pnpm` | true | Whether to install pnpm |
| `install_ansible` | true | Whether to install Ansible |
| `install_github_cli` | true | Whether to install GitHub CLI |
| `install_kubectl` | true | Whether to install kubectl |
| `kubectl_version` | "1.28.2" | kubectl version to install |
| `setup_kubernetes` | false | Whether to configure Kubernetes context |
| `kubeconfig_content` | "" | Content of kubeconfig file (can be set from GitHub Actions secrets) |

## Usage

### Using with a GitHub Actions workflow

```yaml
- name: Setup runner dependencies
  run: |
    # Ensure basic tools are available
    sudo apt-get update
    sudo apt-get install -y make python3-pip python3-venv

    # Create a temporary inventory file for localhost
    mkdir -p /tmp
    echo "[github_runners]" > /tmp/github_runner_inventory.ini
    echo "localhost ansible_connection=local" >> /tmp/github_runner_inventory.ini

    # Install Ansible if needed
    if ! command -v ansible-playbook &> /dev/null; then
      python3 -m pip install ansible
    fi

    # Run the Ansible playbook locally
    ansible-playbook ansible/github_actions_setup.yml -i /tmp/github_runner_inventory.ini -e "project_root=$(pwd)"
```

### Setting up Kubernetes with GitHub Actions

To configure Kubernetes in your GitHub workflow:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Kubernetes context
        run: |
          ansible-playbook ansible/runner.yaml -i /tmp/github_runner_inventory.ini \
            -e "setup_kubernetes=true" \
            -e "kubeconfig_content=${{ secrets.KUBECONFIG }}"

      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s/deployment.yaml
```

### Using with Make

Add the following target to your Makefile:

```make
.PHONY: github-runner-setup
github-runner-setup:
	@echo "Setting up GitHub Actions runner dependencies..."
	@mkdir -p /tmp
	@echo "[github_runners]" > /tmp/github_runner_inventory.ini
	@echo "localhost ansible_connection=local" >> /tmp/github_runner_inventory.ini
	ansible-playbook ansible/github_actions_setup.yml -i /tmp/github_runner_inventory.ini -e "project_root=$(shell pwd)"
```

Then run `make github-runner-setup` to install all dependencies.

## Benefits

- **Centralized management**: All dependencies are defined in one place
- **Consistent environments**: Ensures all runners have identical setups
- **Reduced workflow size**: Workflows become shorter and easier to maintain
- **Simplified maintenance**: Update dependencies in one place instead of in every workflow file