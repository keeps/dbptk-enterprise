#!/bin/bash

# Get the first argument as the DBPTK directory path
DBPTK_DIR="$1"
# Get the second argument as the DBPTK host
HOST="$2"

# Check if the DBPTK directory argument is provided
if [ -z "$1" ]; then
  echo "Error: Missing path to the dbvtk directory."
  echo "Syntax: $0 [dbptk_direcrtory] [dbptk_host]"
  exit 1
fi

# Check if the DBPTK host argument is provided
if [ -z "$2" ]; then
  echo "Error: Missing DBPTK host."
  echo "Syntax: $0 [dbptk_direcrtory] [dbptk_host]"
  exit 1
fi

#loop through the system databases
for subdir in "$DBPTK_DIR/databases"/*; do
  UUID=$(basename "$subdir")
  DATABASE_FILE="$DBPTK_DIR/databases/$UUID/database-$UUID.json"

  if [ ! -f "$DATABASE_FILE" ]; then
    echo "Database file $DBPTK_DIR/databases/$UUID/database-$UUID.json does not exist."
  else
    STATUS=$(jq -r '.status' "$DATABASE_FILE")
    if [ "$STATUS" == "AVAILABLE" ]; then
      echo "Processing database with ID $UUID"
      echo "Deleting collection..."

      # Delete the existing collection
      RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k "http://$HOST/api/v1/database/$UUID/collection/$UUID" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -X 'DELETE')

      if [ "$RESPONSE" -eq 200 ]; then
        echo "Collection deleted successfully."
      else
        echo "Error deleting collection. HTTP Code: $RESPONSE"
      fi

      echo "Creating collection for database..."

      # Create collection for the database
      RESPONSE=$(curl -s -k -o /dev/null -w "%{http_code}" -k "http://$HOST/api/v1/database/$UUID/collection" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -X 'POST')

      if [ "$RESPONSE" -eq 200 ]; then
        echo "Collection created successfully."
      else
        echo "Error creating collection. HTTP Code: $RESPONSE"
      fi

      DENORMALIZATIONS=$(find "$DBPTK_DIR/databases/$UUID/" -type f -name 'denormalization-*')

      for DENORMALIZATION_FILE in $DENORMALIZATIONS; do
        
        if [ -f "$DENORMALIZATION_FILE" ]; then
          TABLE_UUID=$(jq -r '.tableUUID' "$DENORMALIZATION_FILE")
          DENORMALIZATION=$(jq -r '.id' "$DENORMALIZATION_FILE")
          echo "Processing denormalization $DENORMALIZATION for table $TABLE_UUID..."

          # Run the denormalization process
          RESPONSE=$(curl -s -k -w "%{http_code}" -k "http://$HOST/api/v1/database/$UUID/collection/$UUID/config/$TABLE_UUID/run" \
                  -H 'Accept: application/json' \
                  -H 'content-type: application/json' \
                  -X 'GET')

          HTTP_CODE="${RESPONSE: -3}"
          JOB_RESPONSE="${RESPONSE::-3}"

          if [ "$HTTP_CODE" -eq 200 ]; then
            JOB_ID=$(echo "$JOB_RESPONSE" | jq -r '.jobId')
            JOB_STATUS=$(echo "$JOB_RESPONSE" | jq -r '.jobStatus')
            JOB_CREATION_TIMER=$(echo "$JOB_RESPONSE" | jq -r '.jobCreationTime')
            echo "$DENORMALIZATION job with ID $JOB_ID for table $TABLE_UUID created at $JOB_CREATION_TIMER.
            Status: $JOB_STATUS."
          else
            echo "Error processing denormalization $DENORMALIZATION for table $TABLE_UUID: $HTTP_CODE"
          fi
        else
          echo "Warning: File $DENORMALIZATION.json not found, skipping..."
        fi
      done
    fi
  fi
done
