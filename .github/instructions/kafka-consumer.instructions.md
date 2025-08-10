---
applyTo: apps/kafka-consumer/**/*
---

# Purpose
Go-based Kafka consumer for processing AI/ML pipeline events and storing data in PostgreSQL.

# Tech Stack
- **Language**: Go 1.21+
- **Message Broker**: Kafka (sarama client)
- **Database**: PostgreSQL with native SQL
- **Serialization**: Protobuf
- **Configuration**: Environment variables
- **Logging**: Structured logging (logrus/zap)
- **Package Manager**: Go modules

# Project Structure
```
apps/kafka-consumer/consumer/
├── cmd/
│   └── consumer/       # Main application entry
├── internal/
│   ├── handlers/       # Event processing logic
│   ├── models/         # Data structures
│   ├── database/       # Database operations
│   ├── kafka/          # Kafka client configuration
│   └── proto/          # Generated protobuf files
├── go.mod
└── go.sum
```

# Coding Style
1. **Go Standards**: Follow gofmt, effective Go principles
2. **Structure**: Standard Go layout, minimal main.go
3. **Error Handling**: Explicit error handling, structured logging
4. **Packages**: Lowercase names, organize by feature
5. **Naming**: Interfaces end with -er when possible

# Kafka Integration

## Consumer Configuration
```go
config := sarama.NewConfig()
config.Consumer.Group.Rebalance.Strategy = sarama.BalanceStrategyRoundRobin
config.Consumer.Offsets.Initial = sarama.OffsetOldest
config.Consumer.Return.Errors = true
config.Consumer.Group.Session.Timeout = 10 * time.Second
config.Consumer.Group.Heartbeat.Interval = 3 * time.Second
```

## Event Processing
1. **Idempotent Processing**: Handle duplicate messages gracefully
2. **Offset Management**: Commit offsets after successful processing
3. **Error Handling**: Implement dead letter queue for failed messages
4. **Deserialization**: Use protobuf for message deserialization

## Performance
1. **Consumer Groups**: Use for horizontal scalability
2. **Batch Processing**: Process messages in batches when possible
3. **Concurrent Processing**: Use goroutines for parallel processing
4. **Monitor Lag**: Track consumer lag and performance metrics

# Database Operations

## Connection Management
```go
db, err := sql.Open("postgres", connectionString)
if err != nil {
    return err
}
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(5)
db.SetConnMaxLifetime(time.Hour)
```

## Transaction Handling
```go
tx, err := db.Begin()
if err != nil {
    return err
}
defer tx.Rollback()

// ... database operations

return tx.Commit()
```

## Data Processing
1. **Validation**: Validate data before database insertion
2. **Bulk Operations**: Use batch inserts for performance
3. **Prepared Statements**: Use for repeated queries
4. **Indexing**: Ensure proper database indexing strategy

# Configuration & Environment
1. **Environment Variables**: Use for all configuration
2. **Validation**: Validate configuration on startup
3. **Secrets**: Never commit secrets, use env vars
4. **Multi-env**: Support dev/staging/prod environments

# Error Handling & Logging
1. **Structured Logging**: Use JSON format for logs
2. **Error Types**: Create custom error types for business logic
3. **Context**: Include correlation IDs and context in logs
4. **Monitoring**: Log performance metrics and health status

# Testing
1. **Unit Tests**: Test business logic thoroughly
2. **Integration Tests**: Test with testcontainers
3. **Mock Dependencies**: Mock Kafka producers and database
4. **Coverage**: Aim for >80% code coverage

# Performance & Monitoring
1. **Health Checks**: Implement HTTP health check endpoint
2. **Metrics**: Expose Prometheus metrics
3. **Resource Usage**: Monitor memory and CPU usage
4. **Graceful Shutdown**: Handle shutdown signals properly

# Development
1. **Code Quality**: Use golangci-lint for linting
2. **Pre-commit**: Run tests and linting before commits
3. **Local Dev**: Use Docker Compose for dependencies
4. **Hot Reload**: Use air for development hot reloading