# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MediCore Server Dockerfile
# Multi-stage build for optimized production image
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Stage 1: Build
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o medicore-server ./cmd/server

# Stage 2: Production
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates postgresql-client tzdata

# Set timezone
ENV TZ=Africa/Algiers
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create non-root user
RUN addgroup -g 1000 medicore && \
    adduser -D -u 1000 -G medicore medicore

# Create directories
RUN mkdir -p /app/storage /app/backups /app/logs && \
    chown -R medicore:medicore /app

# Set working directory
WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/medicore-server .

# Copy database schema
COPY --from=builder /app/database/schema_postgresql.sql ./database/

# Switch to non-root user
USER medicore

# Expose ports
EXPOSE 50051 50052

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:50052/api/health || exit 1

# Set environment variables
ENV DB_HOST=postgres \
    DB_PORT=5432 \
    DB_USER=medicore \
    DB_NAME=medicore_db \
    DB_SSLMODE=disable

# Run the application
CMD ["./medicore-server"]
