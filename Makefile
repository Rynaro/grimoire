.PHONY: help setup run docker-build docker-run docker-clean install clean

help: ## Show this help message
	@echo "Grimoire - Terminal Notes Application"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Run initial setup (install dependencies)
	@./setup.sh

install: ## Install Ruby dependencies
	@echo "Installing dependencies..."
	@bundle install

run: ## Run Grimoire locally
	@ruby grimoire.rb

docker-build: ## Build Docker image
	@echo "Building Docker image..."
	@docker-compose build

docker-run: ## Run Grimoire in Docker
	@echo "Starting Grimoire in Docker..."
	@docker-compose up

docker-shell: ## Open shell in Docker container
	@docker-compose run --rm grimoire /bin/sh

docker-clean: ## Remove Docker containers and images
	@echo "Cleaning Docker resources..."
	@docker-compose down
	@docker rmi grimoire 2>/dev/null || true

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@rm -rf tmp/*.log
	@rm -rf .bundle/
	@rm -rf vendor/

test: ## Run tests (TODO)
	@echo "Tests not yet implemented"

.DEFAULT_GOAL := help
