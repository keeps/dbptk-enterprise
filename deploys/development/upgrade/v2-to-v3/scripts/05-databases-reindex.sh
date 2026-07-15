#!/bin/bash

HOST="$1"

# Check if the DBPTK host argument is provided
if [ -z "$1" ]; then
  echo "Error: Missing DBPTK host."
  echo "Syntax: $0 [dbptk_host]"
  exit 1
fi

echo "Starting databases reindex..."

RESPONSE=$(curl -s -k -w "%{http_code}" -X POST "http://$HOST/api/v1/database/reindex" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json")

HTTP_CODE="${RESPONSE: -3}"

if [[ "$HTTP_CODE" -eq 200 ]]; then
    echo "Databases reindex finished successfully."
else
    echo "Error: Request failed with HTTP code $HTTP_CODE."
    exit 1
fi