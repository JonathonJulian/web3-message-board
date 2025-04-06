FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application with the correct path
RUN CGO_ENABLED=0 GOOS=linux go build -a -o apiserver ./cmd/main.go

# Production stage
FROM alpine:latest

WORKDIR /app

# Add ca certificates for HTTPS
RUN apk --no-cache add ca-certificates

# Copy the binary from builder
COPY --from=builder /app/apiserver .

# Expose the API port
EXPOSE 8080

# Command to run
CMD ["./apiserver"]