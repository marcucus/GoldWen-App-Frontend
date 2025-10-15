#!/bin/bash

# Test script for Data Export API endpoints
# This demonstrates the expected API flow

echo "=== RGPD Data Export API Test ==="
echo ""

# Replace with actual JWT token and base URL in production
JWT_TOKEN="${JWT_TOKEN:-your-jwt-token-here}"
BASE_URL="${BASE_URL:-http://localhost:3000/api/v1}"

echo "1. Requesting data export..."
echo "POST ${BASE_URL}/users/me/export-data"
echo ""

# Make export request
RESPONSE=$(curl -s -X POST "${BASE_URL}/users/me/export-data" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json")

echo "Response: ${RESPONSE}"
echo ""

# Extract exportId (requires jq)
if command -v jq &> /dev/null; then
  EXPORT_ID=$(echo "$RESPONSE" | jq -r '.exportId')
  echo "Export ID: ${EXPORT_ID}"
  echo ""
  
  echo "2. Checking export status (after 5 seconds)..."
  sleep 5
  
  echo "GET ${BASE_URL}/users/me/export-data/${EXPORT_ID}"
  curl -s -X GET "${BASE_URL}/users/me/export-data/${EXPORT_ID}" \
    -H "Authorization: Bearer ${JWT_TOKEN}" | jq '.'
else
  echo "Note: Install 'jq' to parse JSON responses"
  echo "You can manually check the status with:"
  echo "curl -X GET '${BASE_URL}/users/me/export-data/{exportId}' -H 'Authorization: Bearer ${JWT_TOKEN}'"
fi

echo ""
echo "=== Test Complete ==="
