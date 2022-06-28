FROM openjdk:8-jre-buster

LABEL application-name="Database Preservation Toolkit Enterprise" \
      maintainer="admin@keep.pt" \
      vendor="KEEP SOLUTIONS"

VOLUME /tmp
EXPOSE 8080

COPY app.war /app.war

# environment
ENV DBVTK_IMAGE_VERSION=v1.0
ENV DBVTK_RUNNING_IN_DOCKER=yes
ENV DBVTK_HOME=/dbvtk

COPY /docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
