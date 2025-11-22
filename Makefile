.PHONY: build run dev docker-build docker-run clean

# Build the application
build:
	go build -o grimoire .

# Run the application
run: build
	./grimoire

# Run with hot reload for development
dev:
	go run .

# Build Docker image
docker-build:
	docker build -t grimoire:latest .

# Run Docker container
docker-run: docker-build
	docker run -it --rm \
		-v $(PWD)/notes:/notes \
		-e TERM=xterm-256color \
		grimoire:latest

# Run with docker-compose
docker-compose-up:
	docker-compose up --build

# Clean build artifacts
clean:
	rm -f grimoire
	go clean

# Install dependencies
deps:
	go mod download
	go mod tidy

# Run tests
test:
	go test -v ./...

# Format code
fmt:
	go fmt ./...

# Lint code
lint:
	golangci-lint run

# Show help
help:
	@echo "Grimoire - Terminal Note-Taking App"
	@echo ""
	@echo "Available targets:"
	@echo "  build             - Build the application"
	@echo "  run               - Build and run the application"
	@echo "  dev               - Run with go run for development"
	@echo "  docker-build      - Build Docker image"
	@echo "  docker-run        - Run in Docker container"
	@echo "  docker-compose-up - Run with docker-compose"
	@echo "  clean             - Clean build artifacts"
	@echo "  deps              - Install dependencies"
	@echo "  test              - Run tests"
	@echo "  fmt               - Format code"
	@echo "  help              - Show this help message"
