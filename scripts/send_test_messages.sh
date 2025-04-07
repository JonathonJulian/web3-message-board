#!/bin/bash

# Configuration
API_ENDPOINT="http://192.168.1.94/api/messages/"
DURATION_SECONDS=300  # Run for 5 minutes
INTERVAL_SECONDS=5    # Send a message every 5 seconds

echo "Starting test: Sending messages every $INTERVAL_SECONDS seconds for $DURATION_SECONDS seconds"
echo "Endpoint: $API_ENDPOINT"
echo "Press Ctrl+C to stop"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_SECONDS))
MESSAGE_COUNT=0

# Function to send a message
send_message() {
  local count=$1
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local message="Test message #$count at $timestamp"

  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"$message\",\"sender\":\"LogTestScript\"}" \
    $API_ENDPOINT)

  echo "[$timestamp] Sent message #$count: $message"
  echo "Response: $response"
}

# Main loop
while [ $(date +%s) -lt $END_TIME ]; do
  MESSAGE_COUNT=$((MESSAGE_COUNT + 1))
  send_message $MESSAGE_COUNT

  # Sleep for the interval (but check if we've exceeded duration)
  if [ $(date +%s) -lt $END_TIME ]; then
    sleep $INTERVAL_SECONDS
  fi
done

echo "Finished sending $MESSAGE_COUNT messages over $DURATION_SECONDS seconds"