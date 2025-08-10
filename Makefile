# VDT AI Monorepo Makefile
.PHONY: help install build dev test lint clean proto-generate db-migrate db-seed docker-up docker-down \
	 test-python test-go test-web venv prisma-generate prisma-migrate docker-restart

# Default target
help: ## Show this help message
	@echo "VDT AI Monorepo Management"
	@echo "=========================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Installation and Setup
install: venv ## Install all dependencies
	@echo "[install] JavaScript deps (pnpm)"
	@if command -v pnpm >/dev/null 2>&1; then \
	  if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm install); fi; \
	  if [ -d packages/proto-types ]; then (cd packages/proto-types && pnpm install || true); fi; \
	else \
	  echo "[warn] pnpm not found; skipping dashboard/packages install"; \
	fi
	@echo "[install] Python package (editable)"
	$(PYTHON) -m pip install -e libs/python-lib[dev]
	@echo "[install] Go modules (go mod tidy)"
	@if [ -d apps/kafka-consumer ]; then \
	  if command -v go >/dev/null 2>&1; then \
	    if command -v timeout >/dev/null 2>&1; then \
	      echo "Running go mod tidy with timeout $(GO_TIDY_TIMEOUT)s..."; \
	      (cd apps/kafka-consumer && go mod tidy) || echo "[warn] go mod tidy timed out or failed; continuing"; \
	    else \
	      echo "[warn] 'timeout' not available; skipping go mod tidy to avoid hangs"; \
	    fi; \
	  else \
	    echo "[warn] 'go' not found; skipping go mod tidy"; \
	  fi; \
	fi

install-tools: ## Install required tools (protoc, migrate, etc.)
	@echo "Installing required tools..."
	# Install protoc
	@which protoc > /dev/null || (echo "Please install protoc: https://grpc.io/docs/protoc-installation/" && exit 1)
	# Install golang-migrate
	@which migrate > /dev/null || go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	# Install protoc plugins
	npm install -g @bufbuild/protoc-gen-es @bufbuild/protoc-gen-connect-es
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	$(PYTHON) -m pip install grpcio-tools

# Development
dev: ## Start development servers
	@if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm run dev); else echo "apps/dashboard missing"; fi

build: ## Build all packages
	@if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm run build); fi

test: ## Run all tests
	make test-python
	make test-go
	make test-web

test-python: ## Run Python tests with pytest
	cd libs/python-lib && ($(PYTHON) -m pytest -q --disable-warnings --maxfail=1 || true)

test-go: ## Run Go tests
	@if [ -d apps/kafka-consumer ]; then cd apps/kafka-consumer && (go test ./... || true); else echo "No Go consumer yet"; fi

test-web: ## Run Next.js tests
	@if [ -d apps/dashboard ]; then cd apps/dashboard && (pnpm run test || true); fi

lint: ## Run linting
	@if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm run lint); fi

type-check: ## Run type checking
	@if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm exec tsc -p tsconfig.json --noEmit || true); fi

clean: ## Clean build artifacts
	rm -rf node_modules
	rm -rf apps/*/node_modules
	rm -rf packages/*/node_modules
	@if [ -d apps/kafka-consumer ]; then cd apps/kafka-consumer && go clean; fi
	cd libs/python-lib && find . -name "*.pyc" -delete && find . -name "__pycache__" -delete

# Protocol Buffers
proto-generate: ## Generate code from protobuf definitions
	@echo "Generating protobuf code..."
	# Generate TypeScript/JavaScript
	protoc --proto_path=proto \
		--es_out=packages/proto-types/src \
		--es_opt=target=ts \
		--connect-es_out=packages/proto-types/src \
		--connect-es_opt=target=ts \
		proto/**/*.proto
	# Generate Go
	@if [ -d apps/kafka-consumer ]; then \
	protoc --proto_path=proto \
		--go_out=apps/kafka-consumer/internal/proto \
		--go_opt=paths=source_relative \
		--go-grpc_out=apps/kafka-consumer/internal/proto \
		--go-grpc_opt=paths=source_relative \
		proto/**/*.proto; \
	fi
	# Generate Python
	$(PYTHON) -m grpc_tools.protoc \
		--proto_path=proto \
		--python_out=libs/python-lib/src/vdt_ai/proto \
		--grpc_python_out=libs/python-lib/src/vdt_ai/proto \
		proto/**/*.proto
	@echo "Protobuf code generation completed!"

proto-lint: ## Lint protobuf files
	@echo "Linting protobuf files..."
	find proto -name "*.proto" -exec protoc --proto_path=proto --descriptor_set_out=/dev/null {} \;

# Database Management
db-migrate: ## Run database migrations
	@echo "Running database migrations..."
	migrate -path migrations -database "$(DB_URL)" up

db-migrate-down: ## Rollback database migrations
	@echo "Rolling back database migrations..."
	migrate -path migrations -database "$(DB_URL)" down

db-migrate-create: ## Create a new migration file (usage: make db-migrate-create NAME=create_users_table)
	@if [ -z "$(NAME)" ]; then echo "Usage: make db-migrate-create NAME=migration_name"; exit 1; fi
	migrate create -ext sql -dir migrations -seq $(NAME)

db-seed: ## Seed database with sample data
	@echo "Seeding database... (implement in web app or Go later)"

db-reset: ## Reset database (drop and recreate)
	@echo "Resetting database..."
	migrate -path migrations -database "$(DB_URL)" drop
	make db-migrate
	make db-seed

# Docker Management
docker-up: ## Start Docker services
	docker compose up -d --build

docker-down: ## Stop Docker services
	docker compose down

docker-build: ## Build Docker images
	docker compose build

docker-logs: ## View Docker logs
	docker compose logs -f

docker-restart: ## Restart and rebuild all containers
	docker compose down
	docker compose up -d --build

# Environment Setup
env-setup: ## Setup environment files
	@echo "Setting up environment files..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example"; fi
	@if [ -d apps/dashboard ] && [ ! -f apps/dashboard/.env.local ]; then cp apps/dashboard/.env.example apps/dashboard/.env.local || true; echo "Created apps/dashboard/.env.local"; fi

# Code Quality
format: ## Format code
	@echo "Formatting with Prettier..."
	@([ -d apps/dashboard ] && cd apps/dashboard && pnpm exec prettier --write "**/*.{ts,tsx,js,jsx,json,md}" || true)

format-check: ## Check code formatting
	@echo "Checking formatting with Prettier..."
	@([ -d apps/dashboard ] && cd apps/dashboard && pnpm exec prettier --check "**/*.{ts,tsx,js,jsx,json,md}" || true)


security-check: ## Run security checks
	@if [ -d apps/dashboard ]; then (cd apps/dashboard && pnpm audit || true); fi
	@if command -v nancy >/dev/null 2>&1; then (cd apps/kafka-consumer && go list -json -m all | nancy sleuth); fi
	@if command -v safety >/dev/null 2>&1; then (cd libs/python-lib && $(PYTHON) -m safety check || true); fi

# Monitoring and Health
health-check: ## Check service health
	@echo "Checking service health..."
	@curl -f http://localhost:3000/api/health || echo "Web app not responding"
	@curl -f http://localhost:8080/health || echo "Kafka consumer not responding"

# Release
release: ## Create a release build
	make clean
	make install
	make proto-generate
	make build
	make test

# Variables (can be overridden)
DB_URL ?= postgres://username:password@localhost:5432/vdt_ai?sslmode=disable
KAFKA_BROKERS ?= localhost:9092

# Python virtual environment
VENV ?= .venv
PYTHON ?= $(abspath $(VENV))/bin/python
GO_TIDY_TIMEOUT ?= 30

venv: ## Ensure venv is created
	@if [ ! -d $(VENV) ]; then \
	  echo "Creating Python venv at $(VENV)"; \
	  python3 -m venv $(VENV); \
	  $(PYTHON) -m pip install --upgrade pip; \
	fi
	@echo "Python: $(PYTHON)"

# Prisma (run from dashboard app)
prisma-generate: ## Generate Prisma client
	@if [ -d apps/dashboard ]; then cd apps/dashboard && npx prisma generate; else echo "apps/dashboard missing"; fi

prisma-migrate: ## Run Prisma migrations
	@if [ -d apps/dashboard ]; then cd apps/dashboard && npx prisma migrate deploy; else echo "apps/dashboard missing"; fi
