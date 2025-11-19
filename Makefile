.PHONY: help install run dev docker-build docker-run clean test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install dependencies
	pip install -r requirements.txt

run: ## Run Grimoire locally
	python grimoire.py

dev: ## Run Grimoire with development notes directory
	python grimoire.py --notes-dir ./dev-notes

docker-build: ## Build Docker image
	docker-compose build

docker-run: ## Run Grimoire in Docker
	docker-compose run --rm grimoire

docker-dev: ## Run Grimoire in Docker with shell access
	docker-compose run --rm grimoire bash

clean: ## Clean up Python cache files
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete
	find . -type f -name '*.pyo' -delete
	find . -type f -name '*~' -delete

format: ## Format code with black
	black grimoire.py

lint: ## Lint code with flake8
	flake8 grimoire.py --max-line-length=120
