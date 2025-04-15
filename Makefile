# Makefile for managing infrastructure, helm deployments, and configuration
# Variables
ANSIBLE_INVENTORY ?= ansible/inventory.ini
HELM_NAMESPACE ?= web3
VM_NAME ?= web-server-nginx
KUBERNETES_CONTEXT ?= default

# Docker variables
DOCKER_REGISTRY ?= ghcr.io
DOCKER_REPO ?= $(shell basename $(CURDIR))
DOCKER_TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

# Authentication variables
AUTH_METHOD ?= ssh_key
SSH_KEY_FILE ?= ~/.ssh/id_rsa
SSH_PASSWORD ?=
SSH_USER ?=

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  vm-create        - Create VM using Terraform"
	@echo "  vm-delete        - Delete VM using Terraform"
	@echo "  helm-setup       - Create namespace and prepare for Helm deployments"
	@echo "  helm-deploy      - Deploy all Helm charts"
	@echo "  helm-delete      - Delete all Helm deployments"
	@echo "  charts-deploy - Deploy monitoring stack (Grafana, Loki, MinIO)"
	@echo "  monitoring-delete - Delete monitoring stack"
	@echo "  grafana-deploy   - Deploy only Grafana component"
	@echo "  grafana-delete   - Delete only Grafana component"
	@echo "  loki-deploy      - Deploy only Loki component"
	@echo "  loki-delete      - Delete only Loki component"
	@echo "  minio-deploy     - Deploy only MinIO component"
	@echo "  minio-delete     - Delete only MinIO component"
	@echo "  postgres-deploy  - Deploy PostgreSQL operator"
	@echo "  postgres-delete  - Delete PostgreSQL operator deployment"
	@echo "  postgres-cluster-create - Create a PostgreSQL cluster using the operator"
	@echo "  postgres-ui-deploy - Deploy only PostgreSQL operator UI"
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
helm-deploy: helm-setup charts-deploy
	@echo "Helm deployment completed!"

.PHONY: charts-deploy
charts-deploy: helm-setup
	@echo "Deploying monitoring stack (Grafana, Loki, MinIO)..."
	@echo "Setting up Kubernetes namespace..."
	kubectl create namespace $(HELM_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -

	@echo "Updating Helm dependencies..."
	cd monitoring && helm dependency update .

	@echo "Deploying monitoring stack..."
	cd charts && bash deploy.sh \
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
	cd charts && bash deploy.sh \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set loki.enabled=false \
		--set minio.enabled=false \
		--set grafana.enabled=true

.PHONY: loki-deploy
loki-deploy: helm-setup
	@echo "Deploying Loki only..."
	cd charts && bash deploy.sh \
		--namespace $(HELM_NAMESPACE) \
		--timeout 5m \
		--set grafana.enabled=false \
		--set minio.enabled=true \
		--set loki.enabled=true

.PHONY: minio-deploy
minio-deploy: helm-setup
	@echo "Deploying MinIO only..."
	cd charts && bash deploy.sh \
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
ansible-deploy:
	@echo "Running Ansible playbook..."
	@if [ -f ".ansible_venv/bin/activate" ]; then \
		export GITHUB_TOKEN="$(gh auth token)" && \
		. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini $(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',); \
	else \
		export GITHUB_TOKEN="$(gh auth token)" && \
		cd ansible && ansible-playbook msg_board.yaml -i inventory.ini $(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',); \
	fi

.PHONY: ansible-deploy-ssh
ansible-deploy-ssh: ansible-deps
	@echo "Running Ansible playbook with SSH key authentication..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini \
		--private-key=$(SSH_KEY_FILE) \
		-e 'auth={"method":"ssh_key","user":"$(SSH_USER)"}' \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

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
		-e 'auth={"method":"password","user":"$(SSH_USER)"}' \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-nginx
ansible-nginx: ansible-deps
	@echo "Running Ansible Nginx role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags nginx \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-frontend
ansible-frontend: ansible-deps
	@echo "Running Ansible frontend role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags frontend \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-logging
ansible-logging: ansible-deps
	@echo "Running Ansible logging role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags logging \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-api
ansible-api: ansible-deps
	@echo "Running Go role for API..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags api \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-security
ansible-security: ansible-deps
	@echo "Running Ansible security roles..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags security,users,firewall,ssh \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

.PHONY: ansible-hosts
ansible-hosts: ansible-deps
	@echo "Running hosts role..."
	. .ansible_venv/bin/activate && cd ansible && ansible-playbook msg_board.yaml -i inventory.ini --tags hosts \
		$(if $(ANSIBLE_EXTRA_VARS),--extra-vars '$(ANSIBLE_EXTRA_VARS)',)

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
	@echo "Fetching recent API logs from Loki..."
	@curl -s -G "http://grafana.local/loki/loki/api/v1/query" \
		--data-urlencode 'query={job="api"}' \
		--data-urlencode 'limit=100' | \
		jq -r '.data.result[0].values[]? | .[1] // empty' 2>/dev/null || \
		echo "No logs found or error querying Loki API"

.PHONY: logs-debug
logs-debug:
	@echo "Debugging Loki API response (raw output)..."
	@curl -v -G "http://grafana.local/loki/loki/api/v1/query" \
		--data-urlencode 'query={job="api"}' \
		--data-urlencode 'limit=100'

.PHONY: loki-labels
loki-labels:
	@echo "Checking available labels in Loki..."
	@curl -s -G "http://grafana.local/loki/loki/api/v1/labels" | jq

.PHONY: loki-label-values
loki-label-values:
	@echo "Checking values for job label in Loki..."
	@curl -s -G "http://grafana.local/loki/loki/api/v1/label/job/values" | jq

.PHONY: loki-series
loki-series:
	@echo "Checking available series in Loki..."
	@curl -s -G "http://grafana.local/loki/loki/api/v1/series" \
		--data-urlencode 'match={}' | jq

.PHONY: logs-follow
logs-follow:
	@echo "Following API logs with Loki API (will exit after 100 logs, press Ctrl+C to exit sooner)..."
	@echo "Starting from $(shell date -u -d '1 minute ago' '+%Y-%m-%dT%H:%M:%SZ')"
	@current_time=$$(date -u +%s); \
	end_time=$$(( current_time + 300 )); \
	while [ $${current_time} -lt $${end_time} ]; do \
		curl -s -G "http://grafana.local/loki/loki/api/v1/query" \
			--data-urlencode "query={job=\"api\"}" \
			--data-urlencode "start=$(shell date -u -d '1 minute ago' '+%Y-%m-%dT%H:%M:%SZ')" \
			--data-urlencode "limit=10" | \
			jq -r '.data.result[0].values[]? | .[1] // empty' 2>/dev/null; \
		sleep 3; \
		current_time=$$(date -u +%s); \
	done

.PHONY: monitoring-service-logs
monitoring-service-logs:
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

# Let's add a new target that tries to diagnose ingress paths
.PHONY: loki-path-test
loki-path-test:
	@echo "Testing different possible Loki API path configurations..."
	@echo "\n1. Trying http://grafana.local/loki-push (POST):"
	@curl -s -X POST "http://grafana.local/loki-push" -H "Content-Type: application/json" -d '{}' | grep -q "No Content" && echo "✅ Succeeded" || echo "❌ Failed"

	@echo "\n2. Trying http://grafana.local/loki/api/v1/query:"
	@curl -s -G "http://grafana.local/loki/api/v1/query" --data-urlencode 'query={}' | grep -q "result" && echo "✅ Succeeded" || echo "❌ Failed"

	@echo "\n3. Trying http://grafana.local/loki/loki/api/v1/query:"
	@curl -s -G "http://grafana.local/loki/loki/api/v1/query" --data-urlencode 'query={}' | grep -q "result" && echo "✅ Succeeded" || echo "❌ Failed"

	@echo "\n4. Trying http://loki.local/api/v1/query:"
	@curl -s -G "http://loki.local/api/v1/query" --data-urlencode 'query={}' | grep -q "result" && echo "✅ Succeeded" || echo "❌ Failed"

# PostgreSQL Operator Deployment
.PHONY: postgres-deploy
postgres-deploy: helm-setup
	@echo "Deploying PostgreSQL Operator directly with Helm..."
	helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator || true
	helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui || true
	helm repo update
	helm upgrade --install postgres-operator postgres-operator-charts/postgres-operator \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--wait
	helm upgrade --install postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--wait
	@echo "PostgreSQL Operator has been deployed successfully!"
	@echo "You can access the PostgreSQL Operator UI at: http://postgres-ui.local (after setting up ingress)"

.PHONY: postgres-delete
postgres-delete:
	@echo "Deleting PostgreSQL Operator..."
	helm uninstall postgres-operator -n $(HELM_NAMESPACE) || true
	helm uninstall postgres-operator-ui -n $(HELM_NAMESPACE) || true
	kubectl delete postgresql --all -n $(HELM_NAMESPACE) || true

.PHONY: postgres-ui-deploy
postgres-ui-deploy: helm-setup
	@echo "Deploying PostgreSQL Operator UI only..."
	helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui || true
	helm repo update
	helm upgrade --install postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--wait
	@echo "PostgreSQL Operator UI has been deployed successfully!"

.PHONY: postgres-cluster-create
postgres-cluster-create:
	@echo "Creating PostgreSQL cluster using the operator..."
	@echo "Creating a template for message-board-db cluster..."
	@echo 'apiVersion: "acid.zalan.do/v1"' > /tmp/message-board-db.yaml
	@echo 'kind: postgresql' >> /tmp/message-board-db.yaml
	@echo 'metadata:' >> /tmp/message-board-db.yaml
	@echo '  name: message-board-db' >> /tmp/message-board-db.yaml
	@echo '  namespace: $(HELM_NAMESPACE)' >> /tmp/message-board-db.yaml
	@echo 'spec:' >> /tmp/message-board-db.yaml
	@echo '  teamId: "web3"' >> /tmp/message-board-db.yaml
	@echo '  volume:' >> /tmp/message-board-db.yaml
	@echo '    size: 10Gi' >> /tmp/message-board-db.yaml
	@echo '    storageClass: "local-storage"' >> /tmp/message-board-db.yaml
	@echo '  numberOfInstances: 2' >> /tmp/message-board-db.yaml
	@echo '  users:' >> /tmp/message-board-db.yaml
	@echo '    message_board_user:' >> /tmp/message-board-db.yaml
	@echo '      - superuser' >> /tmp/message-board-db.yaml
	@echo '      - createdb' >> /tmp/message-board-db.yaml
	@echo '  databases:' >> /tmp/message-board-db.yaml
	@echo '    message_board: message_board_user' >> /tmp/message-board-db.yaml
	@echo '  postgresql:' >> /tmp/message-board-db.yaml
	@echo '    version: "15"' >> /tmp/message-board-db.yaml
	@echo '    parameters:' >> /tmp/message-board-db.yaml
	@echo '      shared_buffers: "128MB"' >> /tmp/message-board-db.yaml
	@echo '      max_connections: "100"' >> /tmp/message-board-db.yaml
	@echo '      work_mem: "4MB"' >> /tmp/message-board-db.yaml
	@echo '  resources:' >> /tmp/message-board-db.yaml
	@echo '    requests:' >> /tmp/message-board-db.yaml
	@echo '      cpu: 100m' >> /tmp/message-board-db.yaml
	@echo '      memory: 256Mi' >> /tmp/message-board-db.yaml
	@echo '    limits:' >> /tmp/message-board-db.yaml
	@echo '      cpu: 500m' >> /tmp/message-board-db.yaml
	@echo '      memory: 1Gi' >> /tmp/message-board-db.yaml
	@echo '  podAnnotations:' >> /tmp/message-board-db.yaml
	@echo '    prometheus.io/scrape: "true"' >> /tmp/message-board-db.yaml
	@echo '    prometheus.io/port: "9187"' >> /tmp/message-board-db.yaml
	kubectl apply -f /tmp/message-board-db.yaml
	@echo "PostgreSQL cluster creation initiated. It may take several minutes to complete."
	@echo "Check the status with: kubectl get postgresql -n $(HELM_NAMESPACE)"

.PHONY: postgres-logs
postgres-logs:
	@echo "Viewing logs from PostgreSQL Operator and clusters..."
	kubectl logs -n $(HELM_NAMESPACE) -l app.kubernetes.io/name=postgres-operator --tail=20
	@echo "PostgreSQL cluster logs (if exists):"
	kubectl logs -n $(HELM_NAMESPACE) -l application=spilo --tail=20 || echo "No PostgreSQL cluster logs found"

.PHONY: postgres-password
postgres-password:
	@echo "Getting password for the PostgreSQL message_board_user:"
	@CLUSTER=$$(kubectl get postgresql -n $(HELM_NAMESPACE) -o name | head -n1 | awk -F/ '{print $$2}') && \
	if [ -n "$$CLUSTER" ]; then \
		echo "Credentials for cluster: $$CLUSTER" && \
		kubectl get secret $$CLUSTER.message-board-user.credentials -n $(HELM_NAMESPACE) -o 'jsonpath={.data.password}' | base64 -d && echo ""; \
	else \
		echo "No PostgreSQL clusters found in namespace $(HELM_NAMESPACE)"; \
	fi
