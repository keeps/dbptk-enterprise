#!/bin/bash

# Requires the full path to the .mv.db file as an argument
H2_FILE_PATH=$1

if [ -z "$H2_FILE_PATH" ]; then
    echo "Usage error. Please provide the path to the H2 file."
    echo "Example: ./export.sh /opt/data/dbptk/batch_db.mv.db"
    exit 1
fi

if [ ! -f "$H2_FILE_PATH" ]; then
    echo "Error: File not found at $H2_FILE_PATH"
    exit 1
fi

# Check if Java is installed on the host machine
if ! command -v java &> /dev/null; then
    echo "Error: Java is not installed or not in the system PATH."
    exit 1
fi

# Find the exact folder where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
H2_JAR="$SCRIPT_DIR/h2.jar"

# Check if h2.jar is placed next to the script
if [ ! -f "$H2_JAR" ]; then
    echo "Error: h2.jar not found!"
    echo "Please download it and place it in the same folder as this script: $SCRIPT_DIR"
    exit 1
fi

DIR_NAME=$(dirname "$H2_FILE_PATH")
BASE_NAME=$(basename "$H2_FILE_PATH" .mv.db)
OUTPUT_SQL="pg_data_only.sql"
FULL_DUMP="$DIR_NAME/full_dump.sql"

echo "Starting H2 extraction using local JAR..."

# 1. Use local Java to dump the database
java -cp "$H2_JAR" org.h2.tools.Script \
    -url "jdbc:h2:file:$DIR_NAME/$BASE_NAME" \
    -user 'sa' -password '' \
    -script "$FULL_DUMP"

if [ $? -ne 0 ]; then
    echo "Error during H2 extraction. Ensure the file is not locked by another process."
    exit 1
fi

echo "Cleaning syntax and extracting INSERT statements..."

# 2. Filter inserts (multiline) and clean H2 dialect
awk '/^INSERT INTO/ {flag=1} flag {print} /;/ {if(flag) flag=0}' "$FULL_DUMP" | \
sed -E "s/STRINGDECODE\('([^']*)'\)/'\1'/g" | \
sed -e 's/"PUBLIC"\.//g' \
    -e 's/"BATCH_/BATCH_/g' \
    -e 's/" VALUES/ VALUES/g' > "$OUTPUT_SQL"

echo "Success. Data saved to: $OUTPUT_SQL"