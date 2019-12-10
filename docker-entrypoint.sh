#!/bin/sh

# run extension scripts
DIR=/docker-entrypoint.d

if [ -d "$DIR" ]
then
  /bin/run-parts "$DIR"
fi

if [ $# -eq 0 ] ; then
    echo 'Starting'
    exec java -Djavax.xml.parsers.SAXParserFactory=com.sun.org.apache.xerces.internal.jaxp.SAXParserFactoryImpl -jar /app.war
fi
exec $@
