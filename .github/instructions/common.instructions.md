---
applyTo: **
---

# Purpose
The following rules and context apply to all codebase.

# Overview
This is a monorepo contains multiple packages, including a web application, kafka-consumer services, and shared libraries.

# Documentation
1. Read `docs/requirements.md` for more context about our application.
2. Read `docs/todos.md` for our current plans and completed tasks.

# Behavior
When implement new feature
1. Check docs/requirements.md, folder structure and use context7 to check lib documentation for more context. Ask user if necessary with some suggestions of how to implement the feature, compare them.
2. Update the todos list for new tasks need to work on.
3. Execute each task one by one
4. Write unit tests for added functions.
5. Run tests and lint to check if there's any errors and fix until all tests and lints passed
5. Update completed task to the todo list
When fix a bug
1. Summary how to reproduce the bug (usually given by user)
2. Place logs, run and get logs.
3. Analyze the logs to identify the root cause of the bug.
4. Fix the bugs
5. Write tests to cover the bug and prevent regressions.
When make mistake and user report it
1. Verify user report, if not true explain to the user
2. Analyze why you make mistake
3. Summarize that mistake to a clear and concise statement write it into docs/mistakes.md

# Tests & Lint (Mandatory)
1. Python (libs/python-lib)
	- Use pytest. Put tests under `libs/python-lib/tests/` with filenames `test_*.py`.
	- Enforce formatting with Black and isort; lint with Flake8; type-check with mypy.
2. Go (apps/kafka-consumer)
	- Use table-driven unit tests with `_test.go` colocated with packages.
	- Run with `go test ./...` and include `-race` in CI where possible.
3. Next.js (apps/dashboard)
	- Use ESLint (Next.js config). Place component tests under `__tests__/` per module.
	- Prefer Vitest/Jest + Testing Library; avoid coupling to implementation details.

# Quality Gates
Before merging:
1. Build passes for all packages.
2. Lint and type-check pass with zero errors.
3. Unit tests pass (happy path + at least one edge case per new feature).
4. Docker Compose config validates and services are healthy locally.

# Process Hygiene
1. Keep `docs/todos.md` up to date (mark completed items, add new tasks).
2. Update `docs/api.json` and `docs/db_schema.sql` when API/DB change.
3. Prefer Makefile targets for dev flows (tests, lint, build, docker, prisma).

# Data types
1. We use **protobuf** to define our data models and ensure type safety across services.
2. Types will be written in `proto/`, each folder is a scope and contains different versions named `v1`, `v2`, etc.
3. Always use protobuf types if it is a common entity must be shared across services.

# Build tools
1. Use `Makefile` to automate the generation of types, migration, testing and others.