#!/bin/bash
# Removed set -e to allow tests to continue even if one fails

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Process command-line arguments
RUN_LOAD_TESTS=false
LOAD_TEST_ARGS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --load)
      RUN_LOAD_TESTS=true
      shift
      ;;
    --load-*)
      RUN_LOAD_TESTS=true
      LOAD_TEST_ARGS="$LOAD_TEST_ARGS ${1#--load-}"
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --load              Run load tests after functional tests"
      echo "  --load-frontend     Run only frontend load tests"
      echo "  --load-api          Run only API load tests"
      echo "  --load-env ENV      Specify load test environment: quick, low, default"
      echo "  --help              Show this help message"
      echo ""
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}Running Monad Test Suite${NC}"
echo "=================================="

# Function to run tests and report status
run_test() {
  test_name=$1
  test_script=$2

  echo -e "\n${BLUE}Running $test_name tests...${NC}"
  if bash "$test_script"; then
    echo -e "${GREEN}✅ $test_name tests passed${NC}"
    return 0
  else
    echo -e "${RED}❌ $test_name tests failed${NC}"
    return 1
  fi
}

# Track overall status
TESTS_FAILED=0

# Run frontend tests
run_test "Frontend" "tests/frontend/test_frontend.sh" || ((TESTS_FAILED++))

# Run API tests
run_test "API" "tests/api/test_api.sh" || ((TESTS_FAILED++))

# Run monitoring tests
run_test "Monitoring" "tests/monitoring/test_logging.sh" || ((TESTS_FAILED++))

# Run security tests
run_test "Security" "tests/security/test_security.sh" || ((TESTS_FAILED++))

# Run end-to-end tests
run_test "End-to-End" "tests/e2e/test_e2e.sh" || ((TESTS_FAILED++))

# Run load tests if requested
if [ "$RUN_LOAD_TESTS" = true ]; then
  if [ -x "$(command -v artillery)" ]; then
    # Convert our argument format to the load test script format
    LOAD_SCRIPT_ARGS=""
    for arg in $LOAD_TEST_ARGS; do
      case $arg in
        frontend)
          LOAD_SCRIPT_ARGS="$LOAD_SCRIPT_ARGS --frontend"
          ;;
        api)
          LOAD_SCRIPT_ARGS="$LOAD_SCRIPT_ARGS --api"
          ;;
        env=*)
          env_value=${arg#env=}
          LOAD_SCRIPT_ARGS="$LOAD_SCRIPT_ARGS --env $env_value"
          ;;
      esac
    done

    run_test "Load" "tests/load/run_load_tests.sh $LOAD_SCRIPT_ARGS" || ((TESTS_FAILED++))
  else
    echo -e "${RED}Skipping load tests: Artillery is not installed${NC}"
    echo "Please install Artillery with: npm install -g artillery"
  fi
fi

# Print summary
echo -e "\n${BLUE}Test Summary${NC}"
echo "==============="
if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed successfully!${NC}"
  exit 0
else
  echo -e "${RED}$TESTS_FAILED test suite(s) failed${NC}"
  exit 1
fi
