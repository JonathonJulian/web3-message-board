# Web3 Message Board Makefile
# Variables
DOCKER_REGISTRY ?= ghcr.io
DOCKER_REPO ?= web3-message-board
DOCKER_TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  frontend-install   - Install frontend dependencies"
	@echo "  frontend-dev       - Run frontend development server"
	@echo "  frontend-build     - Build frontend for production"
	@echo "  frontend-lint      - Lint frontend code"
	@echo "  frontend-format    - Format frontend code"
	@echo "  docker-build       - Build frontend Docker image"
	@echo "  docker-push        - Push frontend Docker image to registry"
	@echo "  docker-build-multi - Build multi-platform Docker image"

# Docker Commands
.PHONY: docker-build
docker-build:
	@echo "Building frontend Docker image..."
	docker build -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)/frontend:$(DOCKER_TAG) ./frontend

.PHONY: docker-push
docker-push: docker-build
	@echo "Pushing frontend Docker image to registry..."
	docker push $(DOCKER_REGISTRY)/$(DOCKER_REPO)/frontend:$(DOCKER_TAG)

.PHONY: docker-build-multi
docker-build-multi:
	@echo "Building multi-architecture Docker images..."
	docker buildx create --name frontend-builder --use || true
	docker buildx build --platform $(PLATFORMS) -t $(DOCKER_REGISTRY)/$(DOCKER_REPO)/frontend:$(DOCKER_TAG) ./frontend --push
	@echo "Multi-architecture Docker images built successfully!"

# Default target
.DEFAULT_GOAL := help
