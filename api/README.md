# Web3 Message Board API Service

This directory contains the Go API service for the Web3 message board application.

## Overview

The API service provides a blockchain interaction layer for the message board application, allowing users to:
- Post messages to the blockchain
- Retrieve messages from the blockchain
- Like messages with blockchain transactions
- Get transaction status and gas estimates
- Access message history efficiently through indexing

## Technology Stack

- [Go](https://golang.org/) - Programming language
- [Gin](https://github.com/gin-gonic/gin) - Web framework
- [ethers-go](https://github.com/ethereum/go-ethereum) - Ethereum client library
- [zap](https://github.com/uber-go/zap) - Structured logging

## Directory Structure

```
api/
├── cmd/                # Application entrypoints
│   └── server/         # API server command
├── internal/           # Private application code
│   ├── config/         # Configuration handling
│   ├── handlers/       # HTTP request handlers
│   ├── middleware/     # HTTP middleware
│   ├── blockchain/     # Blockchain interaction
│   ├── indexer/        # Message indexing service
│   └── service/        # Business logic
├── pkg/                # Public library code
│   ├── contracts/      # Contract ABI and bindings
│   ├── logger/         # Logging utilities
│   └── metrics/        # Metrics collection
├── scripts/            # Utility scripts
├── .gitignore          # Git ignore file
├── go.mod              # Go module definition
├── go.sum              # Go module checksum
└── README.md           # This file
```

## Setup and Running

### Prerequisites
- Go 1.20 or later
- Access to an Ethereum RPC endpoint (Infura, Alchemy, or local node)

### Local Development

1. Install dependencies:
   ```bash
   go mod download
   ```

2. Set environment variables:
   ```bash
   export RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
   export CONTRACT_ADDRESS=0x1234...5678
   export CHAIN_ID=11155111  # Sepolia testnet
   export LOG_LEVEL=debug
   ```

3. Run the server:
   ```bash
   go run cmd/server/main.go
   ```

### Using Ansible

The API service is deployed using Ansible:

```bash
make ansible-api
```

This will:
1. Install Go on the target server
2. Copy the API service files
3. Configure environment variables with blockchain settings
4. Build and run the service
5. Set up logging with Promtail

## API Documentation

The API exposes the following endpoints:

### Blockchain Interaction
- `POST /api/messages` - Post a new message to the blockchain
- `GET /api/messages` - List messages from the blockchain
- `POST /api/messages/:id/like` - Like a specific message
- `GET /api/gas-price` - Get current gas price estimation

### Transaction Management
- `GET /api/transactions/:hash` - Get transaction status
- `GET /api/transactions/pending` - List pending transactions

### Indexing and Efficiency
- `GET /api/messages/count` - Get total message count
- `GET /api/messages/latest` - Get latest messages (faster than on-chain query)
- `GET /api/messages/popular` - Get most liked messages

## Simulated Mode

For development and testing, the API can run in a simulated blockchain mode using the `SimulatedMessageBoard` implementation. This allows for testing without actual blockchain interactions.

To enable simulation mode:
```bash
export SIMULATION_MODE=true
```

## Logging

The API service logs in structured JSON format compatible with Loki. Key information logged includes:
- Blockchain interactions
- Transaction details
- Error conditions
- Performance metrics

Logs are collected by Promtail and sent to the Loki service for centralized logging.

## Metrics

The service exposes Prometheus-compatible metrics at the `/metrics` endpoint, which include:
- Transaction counts and status
- Gas prices and usage
- Response times
- Error rates