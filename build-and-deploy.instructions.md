# Build and Deploy Instructions

This document guides local development, testing, building, and deployment for VDT AI.

## Prerequisites

- Node.js >= 20, npm >= 9
- Python >= 3.10
- Go >= 1.22
- Docker and Docker Compose
- protoc and plugins (see `make install-tools`)

## Setup

1. Create Python virtualenv and install deps
   - `make venv`
   - `make install`
2. Generate protobufs (optional early phase): `make proto-generate`
3. Start infra and apps: `make docker-up`

## Database

- Schema: `docs/db_schema.sql`. Apply via migration tool or as Postgres init script.
- Retention: Schedule `SELECT cleanup_old_data(now() - interval '30 days');`.

## Tests

- Python (libs/python-lib): `make test-python`
  - Layout: `libs/python-lib/tests/` with pytest. Use fixtures for Kafka/Postgres fakes.
  - Coverage: enable `pytest-cov` with `--cov=vdt_ai` in CI.
- Go (apps/kafka-consumer): `make test-go`
  - Layout: standard `_test.go` alongside packages and `internal/` for non-public.
  - Use table-driven tests. Add testify when needed.
- Next.js (apps/dashboard): `make test-web`
  - Add Vitest or Jest with `__tests__/` per component/module.

## Lint and Formatting

- JS/TS: ESLint (Next.js preset) and Prettier. Run `npm run lint` and `npm run format`.
- Python: Black, isort, Flake8, mypy. Suggested pre-commit in future.
- Go: `gofmt`, `go vet`, staticcheck (recommended in CI).

## Docker Images

- Web: `docker/web/Dockerfile` builds Next.js standalone. Exposes 3000.
- Kafka Consumer: `docker/kafka-consumer/Dockerfile`. Produces `consumer` binary.
- Compose: `docker-compose.yml` wires Postgres, Kafka, Redis, web, consumer, and tooling.

## Prisma + Database Integration

- Next.js uses Prisma (already integrated on Vercel).
- Local steps:
  - Add `apps/dashboard/prisma/schema.prisma` targeting compose Postgres.
  - Run `make prisma-generate` and `make prisma-migrate` to sync schema.
  - Set `DATABASE_URL` in `apps/dashboard/.env` to match compose.

### Connecting Go to Prisma-managed DB

- Prisma migrates schema; Go uses `pgx` or `database/sql` with the same `DATABASE_URL`.
- Go does not call Prisma directly. Consider sqlc to share queries later.

## CI/CD Overview

- Steps:
  1. Install tools: `make install-tools`
  2. Setup Python venv and install: `make venv && make install`
  3. Lint/type-check: `npm run lint && npm run type-check`
  4. Tests: `make test`
  5. Build images: `make docker-build`
  6. Push and deploy.

## Security Notes

- Hash API keys in DB.
- Use secret managers in CI/CD.
- Non-root users in containers.

## Troubleshooting

- Postgres won’t start: check volume permissions and ports.
- Kafka healthcheck flaky: increase retries or startup delay.
- Next.js dev mounts slow: develop outside Docker or tweak polling.
