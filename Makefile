# Makefile for managing infrastructure, helm deployments, and configuration
# Variables
ANSIBLE_INVENTORY ?= ansible/inventory.ini
ANSIBLE_VAULT_PASS ?= ansible/.vault_pass
HELM_NAMESPACE ?= monad
VM_NAME ?= web-server-nginx-cloud-5
KUBERNETES_CONTEXT ?= k3s-main

# Docker variables
DOCKER_REGISTRY ?= ghcr.io
DOCKER_REPO ?= $(shell basename $(CURDIR))
DOCKER_TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

# Authentication variables
AUTH_METHOD ?= ssh_key
SSH_KEY_FILE ?= ~/.ssh/id_rsa
SSH_PASSWORD ?=

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  vm-create        - Create VM using Terraform"
	@echo "  vm-delete        - Delete VM using Terraform"
	@echo "  helm-setup       - Create namespace and prepare for Helm deployments"
	@echo "  helm-deploy      - Deploy all Helm charts"
	@echo "  helm-delete      - Delete all Helm deployments"
	@echo "  monitoring-deploy - Deploy monitoring stack (Grafana, Loki, MinIO)"
	@echo "  monitoring-delete - Delete monitoring stack"
	@echo "  grafana-deploy   - Deploy only Grafana component"
	@echo "  grafana-delete   - Delete only Grafana component"
	@echo "  loki-deploy      - Deploy only Loki component"
	@echo "  loki-delete      - Delete only Loki component"
	@echo "  minio-deploy     - Deploy only MinIO component"
	@echo "  minio-delete     - Delete only MinIO component"
	@echo "  monitoring-logs  - View logs from monitoring stack components"
	@echo "  monitoring-port-forward - Set up port forwarding for Grafana and MinIO"
	@echo "  ansible-deploy   - Run Ansible playbook to configure servers"
	@echo "  ansible-deploy-ssh - Run Ansible with explicit SSH key auth (SSH_KEY_FILE=/path/to/key)"
	@echo "  ansible-deploy-password - Run Ansible with password auth (SSH_PASSWORD=your_password)"
	@echo "  ansible-api      - Run only API role with Ansible"
	@echo "  ansible-frontend - Run only frontend role with Ansible"
	@echo "  ansible-nginx    - Run only Nginx role with Ansible"
	@echo "  ansible-logging  - Run only logging role with Ansible"
	@echo "  ansible-security - Run only security roles with Ansible"
	@echo "  ansible-hosts    - Run hosts role with Ansible"
	@echo "  github-runner-setup - Setup dependencies for GitHub Actions runner"
	@echo "  terraform-minio-setup - Set up MinIO bucket for Terraform state storage"
	@echo "  terraform-minio-init - Initialize Terraform with MinIO backend"
	@echo "  terraform-apply  - Apply Terraform config using MinIO backend"
	@echo "  setup-all        - Set up complete environment (VM, Helm, Ansible)"
	@echo "  teardown         - Clean up the entire environment"
	@echo "  logs             - View logs from the deployed services"
	@echo "  docker-build-frontend - Build frontend Docker image"
	@echo "  docker-build-api - Build API Docker image"
	@echo "  docker-build-all - Build all Docker images"
	@echo "  docker-push-frontend - Push frontend Docker image to registry"
	@echo "  docker-push-api - Push API Docker image to registry"
	@echo "  docker-push-all - Push all Docker images to registry"
	@echo "  docker-build-multiarch - Build multi-architecture Docker images"
	@echo "  docker-compose-up - Start all services with Docker Compose"
	@echo "  docker-compose-down - Stop all services with Docker Compose"

# VM Management
.PHONY: vm-create
vm-create:
	@echo "Creating VM using Terraform..."
	cd terraform && terraform init && terraform apply -auto-approve

.PHONY: vm-delete
vm-delete:
	@echo "Deleting VM using Terraform..."
	cd terraform && terraform destroy -auto-approve

# Kubernetes/Helm Management
.PHONY: helm-setup
helm-setup:
	@echo "Setting up Kubernetes namespace and Helm repositories..."
	kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update

.PHONY: helm-deploy
helm-deploy: helm-setup monitoring-deploy
	@echo "Helm deployment completed!"

.PHONY: monitoring-deploy
monitoring-deploy: helm-setup
	@echo "Deploying monitoring stack (Grafana, Loki, MinIO)..."
	@echo "Setting up Kubernetes namespace..."
	kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

	@echo "Updating Helm dependencies..."
	cd monitoring && helm dependency update .

	@echo "Deploying monitoring stack..."
	cd monitoring && helm upgrade --install monitoring . \
	  --namespace $(HELM_NAMESPACE) \
	  --timeout 10m

	@echo "Waiting for deployments to be ready..."
	kubectl rollout status deployment -n $(HELM_NAMESPACE) -w --timeout=180s || true

	@echo "Deployment completed!"
	@echo "You can check the status of your pods with: kubectl get pods -n $(HELM_NAMESPACE)"

# Individual component deployments
.PHONY: grafana-deploy
grafana-deploy: helm-setup
	@echo "Deploying Grafana only..."
	cd monitoring && helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set loki.enabled=false \
		--set minio.enabled=false \
		--set grafana.enabled=true

.PHONY: loki-deploy
loki-deploy: helm-setup
	@echo "Deploying Loki only..."
	cd monitoring && helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=false \
		--set minio.enabled=true \
		--set loki.enabled=true

.PHONY: minio-deploy
minio-deploy: helm-setup
	@echo "Deploying MinIO only..."
	cd monitoring && helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=false \
		--set loki.enabled=false \
		--set minio.enabled=true

# Individual component deletions
.PHONY: grafana-delete
grafana-delete:
	@echo "Deleting Grafana component..."
	helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=false \
		--set loki.enabled=true \
		--set minio.enabled=true || true
	kubectl delete pv monitoring-grafana-pv --ignore-not-found=true

.PHONY: loki-delete
loki-delete:
	@echo "Deleting Loki component..."
	helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=true \
		--set loki.enabled=false \
		--set minio.enabled=true || true
	kubectl delete pv monitoring-loki-write-pv-50gb --ignore-not-found=true
	kubectl delete pv monitoring-loki-backend-pv-50gb --ignore-not-found=true

.PHONY: minio-delete
minio-delete:
	@echo "Deleting MinIO component..."
	helm upgrade --install monitoring . \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=true \
		--set loki.enabled=true \
		--set minio.enabled=false || true
	kubectl delete pv monitoring-minio-pv --ignore-not-found=true

.PHONY: helm-delete
helm-delete:
	@echo "Deleting Helm deployments..."
	helm uninstall monitoring -n $(HELM_NAMESPACE) || true

.PHONY: monitoring-delete
monitoring-delete:
	@echo "Deleting monitoring stack..."
	kubectl delete namespace $(HELM_NAMESPACE) --ignore-not-found=true
	kubectl delete pv monitoring-minio-pv --ignore-not-found=true
	kubectl delete pv monitoring-loki-write-pv-50gb --ignore-not-found=true
	kubectl delete pv monitoring-loki-backend-pv-50gb --ignore-not-found=true
	kubectl delete pv monitoring-grafana-pv --ignore-not-found=true

.PHONY: monitoring-logs
monitoring-logs:
	@echo "Viewing logs from monitoring stack components..."
	@echo "Loki logs:"
	kubectl logs -n $(HELM_NAMESPACE) -l app=loki --tail=20
	@echo "Grafana logs:"
	kubectl logs -n $(HELM_NAMESPACE) -l app.kubernetes.io/name=grafana --tail=20
	@echo "MinIO logs:"
	kubectl logs -n $(HELM_NAMESPACE) -l app=minio --tail=20

.PHONY: monitoring-port-forward
monitoring-port-forward:
	@echo "Setting up port forwarding for monitoring services..."
	kubectl port-forward svc/monitoring-grafana 3000:80 -n $(HELM_NAMESPACE) &
	kubectl port-forward svc/monitoring-minio-console 9001:9001 -n $(HELM_NAMESPACE) &
	@echo "Grafana available at http://localhost:3000"
	@echo "MinIO Console available at http://localhost:9001"

# Ansible Management
.PHONY: ansible-deps
ansible-deps:
	@echo "Installing Ansible dependencies..."
	@# Check if we already have a managed environment
	@if [ -f ".ansible_deps_installed" ] && [ -d ".ansible_venv" ]; then \
		echo "Using existing Ansible virtual environment"; \
		if [ ! -f "activate_ansible_env.sh" ]; then \
			echo "#!/bin/bash" > activate_ansible_env.sh; \
			echo "# This script activates the Ansible virtual environment" >> activate_ansible_env.sh; \
			echo "source $(shell pwd)/.ansible_venv/bin/activate" >> activate_ansible_env.sh; \
			echo "echo \"Ansible virtual environment activated. Run 'deactivate' to exit.\"" >> activate_ansible_env.sh; \
			chmod +x activate_ansible_env.sh; \
		fi; \
	else \
		echo "Setting up Ansible environment..."; \
		if [ -n "$$USE_SIMPLIFIED_SETUP" ]; then \
			echo "Using simplified setup (skipping full runner setup)..."; \
			python3 -m venv .ansible_venv; \
			. .ansible_venv/bin/activate && pip install ansible kubernetes>=24.2.0 PyYAML>=6.0; \
			touch .ansible_deps_installed; \
		else \
			$(MAKE) github-runner-setup; \
		fi; \
	fi

.PHONY: ansible-deploy
ansible-deploy: ansible-deps
	@echo "Running Ansible playbook..."
	@if [ -f ".ansible_venv/bin/activate" ]; then \
		. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini; \
	else \
		cd ansible && ansible-playbook msg_board.yaml -i inventory.ini; \
	fi

.PHONY: ansible-deploy-ssh
ansible-deploy-ssh: ansible-deps
	@echo "Running Ansible playbook with SSH key authentication..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini \
		--private-key=$(SSH_KEY_FILE) \
		-e 'auth={"method":"ssh_key"}'

.PHONY: ansible-deploy-password
ansible-deploy-password: ansible-deps
	@if [ -z "$(SSH_PASSWORD)" ]; then \
		echo "Error: SSH_PASSWORD must be provided for password authentication"; \
		echo "Usage: make ansible-deploy-password SSH_PASSWORD=your_password"; \
		exit 1; \
	fi
	@echo "Running Ansible playbook with password authentication..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini \
		--extra-vars "ansible_password=$(SSH_PASSWORD) ansible_become_password=$(SSH_PASSWORD)" \
		-e 'auth={"method":"password"}'

.PHONY: ansible-nginx
ansible-nginx: ansible-deps
	@echo "Running Ansible Nginx role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags nginx

.PHONY: ansible-frontend
ansible-frontend: ansible-deps
	@echo "Running Ansible frontend role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags frontend

.PHONY: ansible-logging
ansible-logging: ansible-deps
	@echo "Running Ansible logging role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags logging

.PHONY: ansible-api
ansible-api: ansible-deps
	@echo "Running Go role for API..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags api

.PHONY: ansible-security
ansible-security: ansible-deps
	@echo "Running Ansible security roles..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags security,users,firewall,ssh

.PHONY: ansible-hosts
ansible-hosts: ansible-deps
	@echo "Running hosts role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags hosts

# Complete Environment Management
.PHONY: setup-all
setup-all: vm-create helm-deploy ansible-deploy
	@echo "Complete environment setup finished!"

.PHONY: teardown
teardown: helm-delete vm-delete
	@echo "Environment teardown complete!"

# Utility Functions
.PHONY: logs
logs:
	@echo "Viewing logs from Loki and Grafana..."
	kubectl logs -n $(HELM_NAMESPACE) -l app=loki --tail=20
	kubectl logs -n $(HELM_NAMESPACE) -l app.kubernetes.io/name=grafana --tail=20
	kubectl logs -n $(HELM_NAMESPACE) -l app=minio --tail=20

# Utility function to check VM status
.PHONY: vm-status
vm-status: ansible-deps
	@echo "Checking VM status..."
	. .ansible_venv/bin/activate && cd ansible && ansible $(VM_NAME) -i inventory.ini -m command -a "uptime"

# Get service endpoints
.PHONY: get-endpoints
get-endpoints:
	@echo "Getting service endpoints..."
	@echo "Grafana: http://$(shell kubectl get ing -n $(HELM_NAMESPACE) -o jsonpath='{.items[0].spec.rules[0].host}')/grafana"
	@echo "Loki: http://$(shell kubectl get ing -n $(HELM_NAMESPACE) -o jsonpath='{.items[0].spec.rules[0].host}')/loki"
	@echo "MinIO: http://$(shell kubectl get ing -n $(HELM_NAMESPACE) -o jsonpath='{.items[0].spec.rules[0].host}')/minio"

.PHONY: monitoring-pv-check
monitoring-pv-check:
	@echo "Checking Persistent Volume status for monitoring stack..."
	kubectl get pv,pvc -n $(HELM_NAMESPACE)

# Terraform MinIO Backend Setup
.PHONY: terraform-minio-setup
terraform-minio-setup:
	@echo "Setting up MinIO for Terraform state storage..."
	# Port-forward MinIO service
	$(eval PF_PID := $(shell kubectl port-forward svc/monitoring-minio 9000:9000 -n $(HELM_NAMESPACE) & echo $$!))
	@echo "MinIO port-forwarding started with PID: $(PF_PID)"
	@sleep 5
	# Install MinIO client if not present
	if ! command -v mc &> /dev/null; then \
		echo "Installing MinIO client..." && \
		curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc && \
		chmod +x mc && \
		sudo mv mc /usr/local/bin/; \
	fi
	# Configure MinIO client
	mc alias set minio-local http://localhost:9000 minioadmin minioadmin
	# Create bucket for Terraform state if it doesn't exist
	if ! mc ls minio-local/terraform-state &> /dev/null; then \
		echo "Creating terraform-state bucket..." && \
		mc mb minio-local/terraform-state; \
	else \
		echo "terraform-state bucket already exists"; \
	fi
	# Set AWS credentials for Terraform
	mkdir -p ~/.aws
	echo "[default]" > ~/.aws/credentials
	echo "aws_access_key_id = minioadmin" >> ~/.aws/credentials
	echo "aws_secret_access_key = minioadmin" >> ~/.aws/credentials
	# Kill port-forwarding
	kill $(PF_PID) || true

.PHONY: terraform-minio-init
terraform-minio-init: terraform-minio-setup
	@echo "Initializing Terraform with MinIO backend..."
	cd terraform && terraform init \
		-backend-config="endpoint=http://localhost:9000" \
		-backend-config="access_key=minioadmin" \
		-backend-config="secret_key=minioadmin" \
		-migrate-state

.PHONY: terraform-apply
terraform-apply: terraform-minio-init
	@echo "Applying Terraform configuration with MinIO backend..."
	cd terraform && terraform apply

# CI test target for GitHub Actions
.PHONY: ci-test
ci-test:
	@echo "Running tests in CI environment..."
	@echo "Note: This target is meant to be used in GitHub Actions"
	bash tests/run_tests.sh

# Docker commands
.PHONY: docker-build-frontend
docker-build-frontend:
	@echo "Building frontend Docker image..."
	docker build -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)-frontend:$(DOCKER_TAG) ./frontend

.PHONY: docker-build-api
docker-build-api:
	@echo "Building API Docker image..."
	docker build -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)-api:$(DOCKER_TAG) ./api

.PHONY: docker-build-all
docker-build-all: docker-build-frontend docker-build-api
	@echo "All Docker images built successfully!"

.PHONY: docker-push-frontend
docker-push-frontend: docker-build-frontend
	@echo "Pushing frontend Docker image to registry..."
	docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)-frontend:$(DOCKER_TAG)

.PHONY: docker-push-api
docker-push-api: docker-build-api
	@echo "Pushing API Docker image to registry..."
	docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)-api:$(DOCKER_TAG)

.PHONY: docker-push-all
docker-push-all: docker-push-frontend docker-push-api
	@echo "All Docker images pushed successfully!"

.PHONY: docker-build-multiarch
docker-build-multiarch:
	@echo "Building multi-architecture Docker images..."
	docker buildx create --name multiarch-builder --use || true
	docker buildx build --platform $(PLATFORMS) -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)-frontend:$(DOCKER_TAG) ./frontend --push
	docker buildx build --platform $(PLATFORMS) -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)-api:$(DOCKER_TAG) ./api --push
	@echo "Multi-architecture Docker images built successfully!"

.PHONY: docker-compose-up
docker-compose-up:
	@echo "Starting all services with Docker Compose..."
	docker-compose up -d

.PHONY: docker-compose-down
docker-compose-down:
	@echo "Stopping all services with Docker Compose..."
	docker-compose down

# GitHub Actions Runner Setup
.PHONY: github-runner-setup
github-runner-setup:
	@echo "Setting up GitHub Actions runner dependencies..."
	# Create a temporary inventory file for localhost
	@mkdir -p /tmp
	@echo "[github_runners]" > /tmp/github_runner_inventory.ini
	@echo "localhost ansible_connection=local" >> /tmp/github_runner_inventory.ini
	# Run the Ansible playbook locally with current directory as project root
	ansible-playbook ansible/runner.yaml -i /tmp/github_runner_inventory.ini -e "project_root=$(shell pwd)"
	@echo ""
	@echo "Setup completed successfully!"
	@if [ -f "activate_ansible_env.sh" ]; then \
		echo "To activate the Ansible virtual environment, run:"; \
		echo "  source ./activate_ansible_env.sh"; \
	fi

# Default target
.DEFAULT_GOAL := help
