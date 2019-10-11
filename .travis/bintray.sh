#!/bin/bash

if [ "$TRAVIS_BRANCH" == "staging" ]; then
  #Use staging version of DBVTK
  DBVTK_VERSION="staging"
else
  #get lastest version of DBVTK
  DBVTK_VERSION=$(curl -s  https://api.bintray.com/packages/keeps/db-visualization-toolkit/db-visualization-toolkit/versions/_latest \
    | sed 's/,/,\n/g' \
    | grep \"name\" \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g' \
    | tr -d '[[:space:]]' \
    | sed 's/^[v\n]//g')
fi

DBVTK="dbvtk-${DBVTK_VERSION}.war"
BINTRAY="https://dl.bintray.com/keeps/db-visualization-toolkit/${DBVTK}"
DBVTK_TARGET="app.war"

echo "=============================="
echo "DBVTK VERSION: ${DBVTK}"
echo "=============================="

#Download dbvtk package from bintray
if [ ! -f $DBVTK_TARGET ]; then
  echo "Downloading ${DBVTK} from bintray"
  mkdir -p "./resources/war"
  response=$(curl --write-out %{http_code} -L $BINTRAY -o $DBVTK_TARGET)
  
  if [ "${response}" != "200" ]; then
    echo "Error! version does not exist in Bintray"
    exit 1;
  fi
fi

