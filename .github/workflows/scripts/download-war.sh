#!/bin/bash

# Downloads the WAR from GitHub packages
# This script will only be used from 'deploy' workflow

DBPTK_UI_WAR_RESOURCE="dbvtk-${DBPTK_UI_VERSION}.war"
GITHUB_PACKAGES_DL_LINK="https://maven.pkg.github.com/keeps/dbptk-ui/com/databasepreservation/visualization/dbvtk/${DBPTK_UI_VERSION}/dbvtk-${DBPTK_UI_VERSION}.war "
DBPTK_RESOURCE_TARGET="app.war"

echo "Downloading version ${DBPTK_UI_VERSION} from GitHub packages"

response=$(curl --write-out %{http_code} -H "Authorization: token ${GITHUB_TOKEN}" -L $GITHUB_PACKAGES_DL_LINK -o $DBPTK_RESOURCE_TARGET)
    
if [ "${response}" != "200" ]; then
  echo "Error! version does not exist in Bintray"
  exit 1;
fi
