#!/bin/bash

DBPTK_DIR=$1
USERNAME="sa"
TEMP_DIR=$(mktemp -d)

# Check if DBPTK_DIR is passed
if [ -z "$1" ]; then
  echo "Error: Missing DBPTK directory."
  echo "Syntax: $0 [dbptk_directory]"
  exit 1
fi

echo "Starting h2 migration..."

# Download the H2 versions required
wget https://repo1.maven.org/maven2/com/h2database/h2/2.3.232/h2-2.3.232.jar
wget https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar

for filepath in $DBPTK_DIR/h2/*.mv.db; do
    dbname=$(basename "$filepath" .mv.db)
    
    # Move the database to a temporary directory for processing
    mv "$filepath" "$TEMP_DIR/"
    
    # Export data from old db file to backup.zip
    echo "Exporting database..."
    java -cp h2-1.4.200.jar org.h2.tools.Script -url jdbc:h2:$TEMP_DIR/$dbname -user $USERNAME -password "" -script backup.zip -options compression zip
    rm -f "$TEMP_DIR/$dbname.mv.db"
    
    # Import data from the backup.zip to the new db file
    echo "Importing data..."
    java -cp h2-2.3.232.jar org.h2.tools.RunScript -url jdbc:h2:$TEMP_DIR/$dbname -user $USERNAME -password "" -script ./backup.zip -options compression zip
    rm -f backup.zip   
    
    # Update schema - Apply schema changes
    echo "Updating database schema..."

    # Write the provided SQL migration commands to a temporary file
    echo "
        ALTER TABLE BATCH_STEP_EXECUTION ADD CREATE_TIME TIMESTAMP NOT NULL DEFAULT '1970-01-01 00:00:00';
        ALTER TABLE BATCH_STEP_EXECUTION ALTER COLUMN START_TIME DROP NOT NULL;

        UPDATE PUBLIC.BATCH_JOB_EXECUTION_PARAMS
        SET STRING_VAL = TO_CHAR(DATE_VAL, 'YYYY-MM-DD') || 'T' || TO_CHAR(DATE_VAL, 'HH24:MI:SS.FF3') || 'Z'
        WHERE TYPE_CD = 'DATE' AND DATE_VAL IS NOT NULL;

        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS DROP COLUMN DATE_VAL;
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS DROP COLUMN LONG_VAL;
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS DROP COLUMN DOUBLE_VAL;

        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN TYPE_CD RENAME TO PARAMETER_TYPE;
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN PARAMETER_TYPE SET DATA TYPE VARCHAR(100);
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN KEY_NAME RENAME TO PARAMETER_NAME;
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN PARAMETER_NAME SET DATA TYPE VARCHAR(100);
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN STRING_VAL RENAME TO PARAMETER_VALUE;
        ALTER TABLE BATCH_JOB_EXECUTION_PARAMS ALTER COLUMN PARAMETER_VALUE SET DATA TYPE VARCHAR(2500);
        
        UPDATE PUBLIC.BATCH_JOB_EXECUTION_PARAMS SET PARAMETER_TYPE='java.util.Date'  WHERE PARAMETER_TYPE = 'DATE';
	      UPDATE PUBLIC.BATCH_JOB_EXECUTION_PARAMS SET PARAMETER_TYPE='java.lang.String'  WHERE PARAMETER_TYPE = 'STRING';

        ALTER TABLE BATCH_JOB_EXECUTION ALTER COLUMN CREATE_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_JOB_EXECUTION ALTER COLUMN START_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_JOB_EXECUTION ALTER COLUMN END_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_JOB_EXECUTION ALTER COLUMN LAST_UPDATED SET DATA TYPE TIMESTAMP(9);

        ALTER TABLE BATCH_STEP_EXECUTION ALTER COLUMN CREATE_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_STEP_EXECUTION ALTER COLUMN START_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_STEP_EXECUTION ALTER COLUMN END_TIME SET DATA TYPE TIMESTAMP(9);
        ALTER TABLE BATCH_STEP_EXECUTION ALTER COLUMN LAST_UPDATED SET DATA TYPE TIMESTAMP(9);
    " > temp_schema_update.sql

    # Execute the SQL script from the temporary file
    java -cp h2-2.3.232.jar org.h2.tools.RunScript -url jdbc:h2:$TEMP_DIR/$dbname -user $USERNAME -password "" -script temp_schema_update.sql

    # Clean up temporary file
    rm -f temp_schema_update.sql

    # Move the updated db back to the original directory
    mv "$TEMP_DIR/$dbname.mv.db" "$DBPTK_DIR/h2/"

    echo "$dbname migrated and schema updated successfully!"
done

# Clean up downloaded H2 jars and temporary directory
rm -f h2-1.4.200.jar
rm -f h2-2.3.232.jar
rm -rf "$TEMP_DIR"


echo "Migration process completed."
