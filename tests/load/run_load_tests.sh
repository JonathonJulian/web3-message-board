#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default target URLs (same as in other test scripts)
TARGET_HOST=${TARGET_HOST:-"192.168.1.75"}
FRONTEND_URL=${FRONTEND_URL:-"http://$TARGET_HOST"}
API_URL=${API_URL:-"http://$TARGET_HOST"}

# Default test configuration
TEST_ENV=${TEST_ENV:-"quick"}  # Default to quick tests

# Check if artillery is installed
if ! command -v artillery &> /dev/null; then
  echo -e "${RED}Error: Artillery is not installed.${NC}"
  echo "Please install Artillery with: npm install -g artillery"
  exit 1
fi

# Directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Process command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--frontend)
      RUN_FRONTEND_ONLY=true
      shift
      ;;
    -a|--api)
      RUN_API_ONLY=true
      shift
      ;;
    -e|--env)
      TEST_ENV="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -f, --frontend    Run frontend load tests only"
      echo "  -a, --api         Run API load tests only"
      echo "  -e, --env ENV     Specify test environment: quick, low, default"
      echo "  -h, --help        Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 --frontend --env quick    # Run quick tests against frontend only"
      echo "  $0 --api                     # Run API tests with default configuration"
      echo "  $0                           # Run all tests with default configuration"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Function to run a specific test scenario
run_load_test() {
  local scenario=$1
  local name=$2
  local target_url=$3

  echo -e "\n${BLUE}Running $name load tests (environment: $TEST_ENV)...${NC}"
  echo "Target URL: $target_url"

  if [ "$TEST_ENV" = "default" ]; then
    TARGET_URL="$target_url" artillery run "scenarios/$scenario"
  else
    TARGET_URL="$target_url" artillery run --environment "$TEST_ENV" "scenarios/$scenario"
  fi

  local status=$?
  if [ $status -eq 0 ]; then
    echo -e "${GREEN}✅ $name load tests completed successfully${NC}"
  else
    echo -e "${RED}❌ $name load tests failed with status $status${NC}"
    return 1
  fi
}

# Run the tests based on options
TESTS_FAILED=0

# Run frontend tests if specified or if no specific test is requested
if [ "$RUN_FRONTEND_ONLY" = true ] || [ "$RUN_API_ONLY" != true ]; then
  run_load_test "frontend-test.yml" "Frontend" "$FRONTEND_URL" || ((TESTS_FAILED++))
fi

# Run API tests if specified or if no specific test is requested
if [ "$RUN_API_ONLY" = true ] || [ "$RUN_FRONTEND_ONLY" != true ]; then
  run_load_test "api-test.yml" "API" "$API_URL" || ((TESTS_FAILED++))
fi

# Print summary
echo -e "\n${BLUE}Load Test Summary${NC}"
echo "================="
if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All load tests passed successfully!${NC}"
  exit 0
else
  echo -e "${RED}$TESTS_FAILED load test(s) failed${NC}"
  exit 1
fi