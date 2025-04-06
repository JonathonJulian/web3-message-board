# Web3 Message Board Test Suite

This directory contains automated tests for the Web3 Message Board application, covering frontend, backend, smart contracts, and infrastructure validation.

## Test Categories

The test suite is organized into the following categories:

- **Frontend Tests**: Verify the Svelte frontend UI and Web3 wallet integration
- **API Tests**: Test the blockchain interaction endpoints
- **Contract Tests**: Verify the smart contract functionality
- **Monitoring Tests**: Validate log generation and retrieval from Loki
- **Security Tests**: Check for exposed ports, TLS configuration, and security headers
- **End-to-End Tests**: Test the complete application flow from frontend to blockchain to logs
- **Load Tests**: Measure system performance under high traffic conditions

## Running the Tests

To run all tests, from the project root, use the Makefile:

```bash
make test
```

To run specific test categories:

```bash
# Frontend tests only
make test-frontend

# API tests only
make test-api

# Contract tests only
make test-contracts

# E2E tests only
make test-e2e

# Load tests only
make load-test
```

## Test Implementation

The tests are implemented using various technologies:

- **Frontend Tests**: Jest and Testing Library
- **API Tests**: Go's testing package
- **Contract Tests**: Foundry (Forge)
- **E2E Tests**: Custom bash scripts with curl
- **Load Tests**: Artillery

## Test Scripts

The repository includes the following test scripts:

```
tests/
├── run_tests.sh                # Main test runner
├── frontend/
│   └── test_frontend.sh        # Frontend tests
├── api/
│   └── test_api.sh             # API tests
├── contracts/                  # Contract tests (via Foundry)
├── monitoring/
│   └── test_logging.sh         # Loki logging tests
├── security/
│   └── test_security.sh        # Security tests
├── e2e/
│   └── test_e2e.sh             # End-to-end tests
└── load/
    └── run_load_tests.sh       # Load tests with Artillery
    └── config.yml              # Artillery configuration
```

## Configuration

By default, all tests will run against the VM IP on port 80. The test scripts use default configuration values that can be overridden using environment variables:

```bash
# Example: Running tests against a specific environment
FRONTEND_URL=https://staging.example.com \
API_URL=https://api.staging.example.com \
GRAFANA_URL=https://grafana.staging.example.com \
LOKI_URL=https://grafana.staging.example.com/loki \
make test
```

For local development testing:

```bash
FRONTEND_URL=http://localhost:5173 \
API_URL=http://localhost:8080 \
make test-frontend test-api
```

## Requirements

- bash
- curl
- jq (for JSON parsing)
- Node.js 18+ (for frontend tests)
- Go 1.21+ (for API tests)
- Foundry (for contract tests)
- Artillery (for load testing)
  - Install Artillery: `npm install -g artillery`

## Load Testing

The load tests use Artillery to simulate high traffic to both the frontend and blockchain API. The test suite includes:

- **API Load Tests**: Test message posting and retrieval operations under load
- **Frontend Load Tests**: Test page loads and navigation under load
- **Blockchain Tests**: Test transaction throughput and gas efficiency

Artillery provides detailed metrics on:
- Response times (p99, p95, median)
- Success/failure rates
- Throughput (requests per second)

## Test Reports

Each test suite generates a summary report with:
- Pass/fail status for each test case
- Performance metrics where applicable
- Error details for failed tests

For CI/CD integration, all tests return appropriate exit codes (0 for success, non-zero for failure).