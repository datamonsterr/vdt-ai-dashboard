# VDT AI Monorepo

A comprehensive monorepo for VDT AI platform using Turborepo, featuring multiple components working together to provide a complete AI/ML solution.

## 🏗️ Architecture

This monorepo contains the following components:

### Applications (`apps/`)
- **`web/`**: Next.js web application with tRPC kafka-consumer API
- **`consumer/`**: Go-based Kafka consumer for event processing

### Libraries (`libs/`)
- **`python-lib/`**: Python library for AI/ML operations and data processing

### Packages (`packages/`)
- **`proto-types/`**: Shared TypeScript types generated from Protocol Buffers

### Infrastructure
- **`proto/`**: Protocol Buffer schema definitions
- **`migrations/`**: Database migration files
- **`docker/`**: Docker configurations

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- Go 1.21+
- Python 3.8+
- Docker and Docker Compose
- Protocol Buffers compiler (`protoc`)
- golang-migrate CLI tool

### Installation

1. **Clone and install dependencies**:
   ```bash
   git clone <repository-url>
   cd vdt-ai
   make install
   ```

2. **Install required tools**:
   ```bash
   make install-tools
   ```

3. **Setup environment**:
   ```bash
   make env-setup
   # Edit .env files as needed
   ```

4. **Start infrastructure services**:
   ```bash
   make docker-up
   ```

5. **Run database migrations**:
   ```bash
   make db-migrate
   ```

6. **Generate protobuf code**:
   ```bash
   make proto-generate
   ```

7. **Start development servers**:
   ```bash
   make dev
   ```

## 📁 Project Structure

```
vdt-ai/
├── apps/
│   ├── web/                    # Next.js web app with tRPC
│   │   ├── src/
│   │   │   ├── pages/         # Next.js pages
│   │   │   ├── lib/           # Database, tRPC, utilities
│   │   │   └── components/    # React components
│   │   ├── package.json
│   │   └── next.config.js
│   └── consumer/        # Go Kafka consumer
│       ├── cmd/consumer/      # Main application
│       ├── internal/          # Internal packages
│       │   ├── config/       # Configuration
│       │   ├── consumer/     # Kafka consumer logic
│       │   ├── database/     # Database connection
│       │   ├── handlers/     # Event handlers
│       │   └── proto/        # Generated protobuf Go code
│       └── go.mod
├── libs/
│   └── python-lib/           # Python AI/ML library
│       ├── src/vdt_ai/      # Source code
│       │   ├── core.py      # Core functionality
│       │   ├── models.py    # ML models
│       │   ├── utils.py     # Utilities
│       │   └── proto/       # Generated protobuf Python code
│       └── setup.py
├── packages/
│   └── proto-types/         # Shared TypeScript types
│       ├── src/            # Generated protobuf TypeScript code
│       └── package.json
├── proto/                   # Protocol Buffer definitions
│   ├── common/v1/          # Common types
│   ├── api/v1/             # API service definitions
│   └── events/v1/          # Event message definitions
├── migrations/             # Database migrations
├── docker/                # Docker configurations
├── Makefile              # Build and development commands
├── turbo.json           # Turborepo configuration
├── docker-compose.yml   # Local development services
└── package.json        # Root package.json
```

## 🛠️ Development

### Available Commands

```bash
# Development
make dev                    # Start all development servers
make build                  # Build all packages
make test                   # Run all tests
make lint                   # Run linting
make clean                  # Clean build artifacts

# Protocol Buffers
make proto-generate         # Generate code from .proto files
make proto-lint            # Lint protobuf files

# Database
make db-migrate            # Run migrations
make db-migrate-down       # Rollback migrations
make db-migrate-create NAME=migration_name  # Create new migration
make db-seed              # Seed database with sample data
make db-reset             # Reset database

# Docker
make docker-up            # Start Docker services
make docker-down          # Stop Docker services
make docker-build         # Build Docker images

# Code Quality
make format               # Format code
make security-check       # Run security checks
make health-check         # Check service health
```

### Adding New Components

#### Adding a New App
1. Create directory in `apps/`
2. Add package.json with appropriate scripts
3. Update root package.json workspaces
4. Add to turbo.json tasks

#### Adding a New Package
1. Create directory in `packages/`
2. Add package.json with build scripts
3. Update root package.json workspaces
4. Reference from apps as needed

### Protocol Buffers Workflow

1. **Define schemas** in `proto/` directory
2. **Generate code** with `make proto-generate`
3. **Use generated types** in your applications:
   - TypeScript: `@vdt-ai/proto-types`
   - Go: `internal/proto/`
   - Python: `vdt_ai.proto`

## 🏛️ Architecture Decisions

### Technology Stack

- **Frontend**: Next.js 14 with TypeScript, Tailwind CSS, Radix UI
- **kafka-consumer API**: tRPC with Drizzle ORM and PostgreSQL
- **Event Processing**: Go with Kafka and Protocol Buffers
- **AI/ML**: Python with scikit-learn, TensorFlow, PyTorch
- **Database**: PostgreSQL with migrations
- **Message Queue**: Apache Kafka
- **Caching**: Redis
- **Monitoring**: Built-in health checks and logging

### Key Design Principles

1. **Type Safety**: Protocol Buffers ensure type safety across all services
2. **Event-Driven**: Kafka enables loose coupling between components
3. **Scalability**: Each component can be scaled independently
4. **Developer Experience**: Turborepo provides fast builds and caching
5. **Observability**: Comprehensive logging and health checks

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database
DATABASE_URL=postgres://username:password@localhost:5432/vdt_ai

# Kafka
KAFKA_BROKERS=localhost:9092

# Redis
REDIS_URL=redis://localhost:6379

# Application
NODE_ENV=development
```

### Database Configuration

The application uses PostgreSQL with the following features:
- UUID primary keys
- JSONB for flexible data storage
- Enum types for constrained values
- Full-text search capabilities
- Indexes for optimal performance

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests for specific workspace
npm run test --workspace=apps/web
cd apps/consumer && go test ./...
cd libs/python-lib && python -m pytest
```

## 📦 Deployment

### Docker Deployment

```bash
# Build production images
make docker-build

# Deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes Deployment

Kubernetes manifests are available in the `k8s/` directory (create as needed).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

### Code Style

- **TypeScript/JavaScript**: Prettier + ESLint
- **Go**: gofmt + golint
- **Python**: Black + isort + flake8

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **Protobuf generation fails**:
   - Ensure `protoc` is installed and in PATH
   - Install required plugins with `make install-tools`

2. **Database connection errors**:
   - Check PostgreSQL is running
   - Verify DATABASE_URL is correct
   - Run migrations with `make db-migrate`

3. **Kafka consumer not receiving messages**:
   - Verify Kafka is running
   - Check topic names match configuration
   - Ensure consumer group ID is unique

4. **Build failures**:
   - Clear node_modules and reinstall
   - Run `make clean && make install`
   - Check all environment variables are set

### Getting Help

- Check the [Issues](link-to-issues) for known problems
- Create a new issue with detailed information
- Join our [Discord](link-to-discord) for community support

## 🔗 Links

- [Turborepo Documentation](https://turbo.build/)
- [Next.js Documentation](https://nextjs.org/docs)
- [tRPC Documentation](https://trpc.io/)
- [Protocol Buffers Guide](https://developers.google.com/protocol-buffers)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
