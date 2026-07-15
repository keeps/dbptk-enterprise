#!/bin/bash

# Ensure all 6 required arguments are provided
if [ "$#" -ne 6 ]; then
    echo "Usage error. Missing parameters."
    echo "Usage: $0 <input_sql> <pg_host> <pg_port> <pg_user> <pg_password> <pg_db>"
    echo "Example: $0 pg_data_only.sql 192.168.2.62 5432 admin dbptk dbptk_db"
    exit 1
fi

INPUT_SQL=$1
PG_HOST=$2
PG_PORT=$3
PG_USER=$4
PG_PASSWORD=$5
PG_DB=$6

if [ ! -f "$INPUT_SQL" ]; then
    echo "Error: File not found at $INPUT_SQL"
    exit 1
fi

echo "Preparing import to PostgreSQL at $PG_HOST:$PG_PORT..."

# 1. Create a temporary consolidated file to disable constraints,
# perform inserts, and update Spring Batch sequences.
TMP_IMPORT="final_import_script.sql"

echo "SET session_replication_role = 'replica';" > "$TMP_IMPORT"
cat "$INPUT_SQL" >> "$TMP_IMPORT"
echo "SET session_replication_role = 'origin';" >> "$TMP_IMPORT"

cat <<EOF >> "$TMP_IMPORT"
-- Update sequences after data import
SELECT setval('batch_job_seq', COALESCE((SELECT MAX(job_instance_id) FROM batch_job_instance), 0) + 1, false);
SELECT setval('batch_job_execution_seq', COALESCE((SELECT MAX(job_execution_id) FROM batch_job_execution), 0) + 1, false);
SELECT setval('batch_step_execution_seq', COALESCE((SELECT MAX(step_execution_id) FROM batch_step_execution), 0) + 1, false);
EOF

echo "Injecting data..."

# 2. Execute psql from a temporary Docker container
docker run --rm \
    --network dbptke_zoonet \
    -v "$(pwd)/$TMP_IMPORT":/import.sql \
    -e PGPASSWORD="$PG_PASSWORD" \
    docker.labs.keep.pt/bu/digitalpreservation/impl/dbptke-dna/postgres:17 \
    psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" -q -f /import.sql

if [ $? -ne 0 ]; then
    echo "Error importing data to PostgreSQL."
    rm "$TMP_IMPORT"
    exit 1
fi

rm "$TMP_IMPORT"

echo "Import completed and Spring Batch sequences updated successfully."