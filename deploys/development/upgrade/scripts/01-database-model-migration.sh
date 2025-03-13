#!/bin/bash

# Get the first argument as the dbvtk directory path
DBPTKE_DIR="$1"
HOST="$2"
DELETE_DBS_NOT_FOUND="false"

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

# Check if the provided directory exists
if [ ! -d "$DBPTKE_DIR" ]; then
  echo "Error: The directory '$DBPTKE_DIR' does not exist."
  exit 1
fi

# Define the path to the 'databases' subdirectory
DATABASES_DIR="$DBPTKE_DIR/databases"

mkdir -p "$DATABASES_DIR/database-garbage/"

# Check if the 'databases' directory exists
if [ ! -d "$DATABASES_DIR" ]; then
  echo "Error: The folder '$DATABASES_DIR' does not exist."
  exit 1
fi

echo "Starting to update database model..."

# Convert 'DATABASES_DIR' to an absolute path
DATABASES_DIR=$(realpath "$DATABASES_DIR")

# Loop through all subdirectories inside the 'databases' folder
for subdir in "$DATABASES_DIR"/*; do
  if [ -d "$subdir" ]; then
    UUID=$(basename "$subdir")

    RESPONSE=$(curl -s -k -w "%{http_code}" "http://$HOST/api/v1/database/$UUID" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -X 'GET')

    HTTP_CODE="${RESPONSE: -3}"
    DATABASE="${RESPONSE::-3}"

    STATUS=$(echo "$DATABASE" | jq -r '.status')
    VERSION=$(echo "$DATABASE" | jq -r '.version')
    LOADED_AT=$(echo "$DATABASE" | jq -r '.loadedAt')
    SIZE=$(echo "$DATABASE" | jq -r '.size')

    echo "$DATABASE" | jq '.metadata' > tmp_metadata.json

    IS_ARRAY=$(echo "$DATABASE" | jq 'if .permissions | type == "array" then 1 else 0 end')

    if [[ "$HTTP_CODE" -ne 200 ]]; then
        echo "Error getting database with id $UUID: Request failed with HTTP code $HTTP_CODE."

        if [[ "$DELETE_DBS_NOT_FOUND" == "true" ]]; then
          echo "Moving directory $subdir to $DATABASES_DIR/database-garbage/"
          mv "$subdir" "$DATABASES_DIR/database-garbage/"
        fi
        continue
    fi

    for input_file in "$subdir"/database-*; do
      if [ -f "$input_file" ]; then
        
        if [[ "$IS_ARRAY" -eq 1 ]]; then
          jq --arg status "$STATUS" --arg siardVersion "$VERSION" --arg loadedAt "$LOADED_AT" --arg size "$SIZE" --argfile metadata tmp_metadata.json '{
            version,
            status: $status,
            siardVersion: $siardVersion,
            id,
            siard: (.siard + {"size": ($size | tonumber)}),
            validation,
            collections,
            availableToSearchAll: true,
            metadata: $metadata,
            loadedAt: $loadedAt,
            permissions: (
              reduce .permissions[] as $perm ({}; . + {($perm): {expiry: null}})
            )
          }' "$input_file" > temp.json && mv temp.json "$input_file"
          echo "File '$input_file' updated successfully."
        else
          jq --arg status "$STATUS" --arg siardVersion "$VERSION" --arg loadedAt "$LOADED_AT" --arg size "$SIZE" --argfile metadata tmp_metadata.json '{
            version,
            status: $status,
            siardVersion: $siardVersion,
            id,
            siard: (.siard + {"size": ($size | tonumber)}),
            validation,
            collections,
            availableToSearchAll: true,
            metadata: $metadata,
            loadedAt: $loadedAt,
            permissions
          }' "$input_file" > temp.json && mv temp.json "$input_file"
          echo "File '$input_file' updated successfully."
        fi
      fi
    done
    rm -f tmp_metadata.json
  fi
done

echo "Database model update completed."
