#!/bin/bash
# Removed set -e to allow script to continue when tests fail

# Frontend URL - detect the server IP or use default
if [ -z "$FRONTEND_URL" ]; then
  # Try to use inventory file IP if available
  if [ -f "ansible/inventory.ini" ]; then
    SERVER_IP=$(grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" ansible/inventory.ini | head -n 1)
    if [ ! -z "$SERVER_IP" ]; then
      FRONTEND_URL="http://$SERVER_IP"
      echo "Using IP from inventory: $FRONTEND_URL"
    else
      FRONTEND_URL="http://192.168.1.94"  # Correct VM IP
      echo "Using default IP: $FRONTEND_URL"
    fi
  else
    FRONTEND_URL="http://192.168.1.94"  # Correct VM IP
    echo "Using default IP: $FRONTEND_URL"
  fi
fi
TIMEOUT=${TIMEOUT:-5}

echo "Testing frontend at $FRONTEND_URL"

# Diagnostic info before tests
echo "### Diagnostic Info ###"
echo "Pinging frontend host to check connectivity..."
FRONTEND_HOST=$(echo $FRONTEND_URL | sed -E 's/https?:\/\///' | sed -E 's/:.*//' | sed -E 's/\/.*//')
ping -c 1 $FRONTEND_HOST || echo "⚠️ Cannot ping the frontend host - network issue detected"

# Basic connectivity check with curl verbose mode
echo "Performing basic connectivity check..."
curl -v --max-time $TIMEOUT -o /dev/null "$FRONTEND_URL" > /tmp/curl_verbose.log 2>&1 || true
echo "Curl verbose output:"
cat /tmp/curl_verbose.log

# Test 1: Check if frontend returns HTML
echo "Test 1: Checking if frontend returns HTML..."
if curl -s --max-time $TIMEOUT -o /tmp/frontend_response.html "$FRONTEND_URL"; then
  # Check if response contains HTML
  if grep -q "<html" /tmp/frontend_response.html; then
    echo "✅ Frontend successfully returned HTML"

    # Check if we got a 404 page
    if grep -q "404 Not Found" /tmp/frontend_response.html; then
      echo "❌ Received a 404 page instead of the application"
      echo "Content received:"
      head -n 20 /tmp/frontend_response.html
      exit 1
    fi
  else
    echo "❌ Frontend response doesn't contain HTML"
    echo "First 50 characters of the response:"
    head -c 50 /tmp/frontend_response.html | xxd -p
    exit 1
  fi
else
  echo "❌ Failed to connect to frontend at $FRONTEND_URL"
  echo "Checking nginx status on the server (if run locally)..."
  systemctl status nginx || echo "⚠️ Cannot check nginx status - either not running as root or not on the same machine"
  exit 1
fi

# Test 2: Check page title
echo "Test 2: Checking page title..."
if grep -q "<title>" /tmp/frontend_response.html; then
  TITLE=$(grep -o "<title>.*</title>" /tmp/frontend_response.html | sed 's/<title>\(.*\)<\/title>/\1/')
  echo "✅ Page has title: $TITLE"

  # Validate that the title is not an error page
  if [[ "$TITLE" == *"404"* || "$TITLE" == *"Error"* || "$TITLE" == *"Not Found"* ]]; then
    echo "❌ The page title indicates an error page: $TITLE"
    exit 1
  fi
else
  echo "⚠️ Page doesn't have a title"
fi

# Test 3: Check for critical elements
echo "Test 3: Checking for critical UI elements..."
# Add checks for elements you expect to find (modify according to your app)
if grep -q "<div" /tmp/frontend_response.html; then
  echo "✅ Found div elements in page"
else
  echo "⚠️ No div elements found in page - This may indicate a problem with the frontend application"
fi

# Clean up temporary files
rm -f /tmp/frontend_response.html

echo "Frontend tests completed successfully!"
exit 0