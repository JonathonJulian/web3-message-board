#!/bin/bash
# Removed set -e to allow tests to continue even if one fails

# API base URL - using VM IP as default with port 80
API_URL=${API_URL:-"http://192.168.1.94"}
TIMEOUT=${TIMEOUT:-5}

echo "Testing API at $API_URL"

# Function to test an API endpoint
test_endpoint() {
  local endpoint=$1
  local expected_status=$2
  local method=${3:-GET}
  local data=${4:-""}
  local full_url="$API_URL$endpoint"

  echo "Testing $method $endpoint"

  # Build curl command based on method
  local cmd="curl -s -o /tmp/api_response.json -w '%{http_code}' --max-time $TIMEOUT"

  if [ "$method" == "POST" ]; then
    cmd="$cmd -X POST -H 'Content-Type: application/json' -d '$data'"
  elif [ "$method" == "PUT" ]; then
    cmd="$cmd -X PUT -H 'Content-Type: application/json' -d '$data'"
  elif [ "$method" == "DELETE" ]; then
    cmd="$cmd -X DELETE"
  fi

  cmd="$cmd '$full_url'"

  # Execute the curl command
  status_code=$(eval $cmd)

  # Check status code
  if [ "$status_code" == "$expected_status" ]; then
    echo "✅ $method $endpoint returned $status_code as expected"
    return 0
  else
    echo "❌ $method $endpoint returned $status_code, expected $expected_status"
    cat /tmp/api_response.json 2>/dev/null || echo "No response body"
    return 1
  fi
}

# Testing only existing endpoints for now
# Once we deploy the new code, we can enable the other tests

# Test 1: Message board endpoints (currently available)
echo "Testing message board endpoints"
test_endpoint "/api/messages" 200 || exit 1
test_endpoint "/api/messages" 201 "POST" '{"message":"Test Message","author":"Automated Test"}' || exit 1

# Future tests (commented until deployed)
# -------------------------------------------------------------------------
# # Health check endpoint
# echo "Testing health endpoint"
# test_endpoint "/api/health" 200

# # User profile endpoints
# echo "Testing profile endpoints"
# test_endpoint "/api/profiles" 200 "POST" '{"address":"0x123456789abcdef","username":"TestUser","bio":"Test bio"}'
# test_endpoint "/api/profiles/0x123456789abcdef" 200

# # Search endpoint
# echo "Testing search endpoint"
# test_endpoint "/api/search/messages?q=Test" 200
# -------------------------------------------------------------------------

# Clean up temporary files
rm -f /tmp/api_response.json

echo "API tests completed successfully!"
exit 0