FROM golang:1.22-alpine AS builder

# Install dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Copy go mod files
COPY apps/kafka-consumer/go.mod ./
RUN go mod download || true

# Copy source code
COPY apps/kafka-consumer/ ./

# Build the application (expects a main package under cmd/consumer when implemented)
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o consumer ./cmd/consumer || true

# Final stage
FROM alpine:latest

# Install ca-certificates for SSL
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy the binary from builder stage (may not exist until code is added)
COPY --from=builder /app/consumer ./consumer

# Ensure a placeholder exists if the binary wasn't built
RUN sh -c 'if [ ! -f ./consumer ]; then printf "#!/bin/sh\necho consumer placeholder - no code yet\nsleep infinity\n" > ./consumer && chmod +x ./consumer; fi'

# Create a non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD ["/root/consumer", "--health-check"] || exit 1

# Run the binary (placeholder until code exists)
CMD ["/root/consumer"]
