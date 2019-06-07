FROM openjdk:8-jdk-alpine

LABEL application-name="Database Visualization Toolkit" \
      maintainer="admin@keep.pt" \
      vendor="KEEP SOLUTIONS"

VOLUME /tmp
EXPOSE 8080

RUN apk --no-cache add curl \
    ; curl -L "https://dl.bintray.com/keeps/db-visualization-toolkit/dbvtk-2.0.0.war" -o "app.war"

# environment
ENV DBVTK_IMAGE_VERSION=v1.0
ENV DBVTK_RUNNING_IN_DOCKER=yes
ENV DBVTK_HOME=/dbvtk
#ENV SOLR_ZOOKEEPER_HOSTS="solr:9983"

COPY /docker-entrypoint.sh /
COPY /docker-entrypoint.d/* /docker-entrypoint.d/

# Work-around to achieve optional copy
ONBUILD COPY /docker-entrypoint.d/* Dockerfile /docker-entrypoint.d/
ONBUILD RUN rm /docker-entrypoint.d/Dockerfile

ENTRYPOINT ["/docker-entrypoint.sh"]
