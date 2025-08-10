# Tests and Linting Best Practices

## Python (libs/python-lib)
- Structure: `src/` for code, `tests/` for unit tests.
- Use pytest fixtures for Kafka/Postgres doubles.
- Naming: `test_*.py`, functions `test_*`.
- Enforce type hints with mypy in CI.
- Style: Black + isort + Flake8; max line length 100.

## Go (apps/kafka-consumer)
- Unit tests `_test.go` colocated with source.
- Table-driven tests for handlers/consumers.
- Use `go test -race` in CI.
- Prefer interfaces for Kafka and DB to enable fakes.

## Next.js (apps/dashboard)
- Co-locate component tests under `__tests__/` next to components.
- Use Vitest/Jest + Testing Library.
- Lint with ESLint (Next.js). Keep strict rules and fix warnings.

## General
- Run `make test` and `npm run lint` before pushing.
- Add pre-commit hooks later to auto-format.
