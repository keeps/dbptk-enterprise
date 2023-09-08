ARG BASE_IMAGE="eclipse-temurin:11-jdk"
ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

FROM eclipse-temurin:11-jdk-alpine AS overlay

RUN apk add --no-cache git \
    && mkdir -p /tmp/cas-overlay \
    && git clone -b 6.6 --single-branch https://github.com/apereo/cas-overlay-template.git /tmp/cas-overlay

RUN mkdir -p cas-overlay
RUN cp -r /tmp/cas-overlay/src cas-overlay/src/
RUN cp -r /tmp/cas-overlay/gradle/ cas-overlay/gradle/

RUN cp -r /tmp/cas-overlay/gradlew /cas-overlay/
RUN cp -r /tmp/cas-overlay/settings.gradle /cas-overlay/
RUN cp -r /tmp/cas-overlay/build.gradle /cas-overlay/
RUN cp -r /tmp/cas-overlay/gradle.properties /cas-overlay/
RUN cp -r /tmp/cas-overlay/lombok.config /cas-overlay/

RUN rm -rf /tmp/cas-overlay

RUN mkdir -p ~/.gradle \
    && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties \
    && echo "org.gradle.configureondemand=true" >> ~/.gradle/gradle.properties \
    && cd cas-overlay \
    && chmod 750 ./gradlew \
    && ./gradlew --version;

COPY ./build.gradle /cas-overlay/

RUN cd cas-overlay \
    && ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS;

FROM $BASE_IMAGE AS cas

LABEL "Organization"="Apereo"
LABEL "Description"="Apereo CAS"

RUN cd / \
    && mkdir -p /etc/cas/config \
    && mkdir -p /etc/cas/services \
    && mkdir -p /etc/cas/saml \
    && mkdir -p cas-overlay;

COPY --from=overlay cas-overlay/build/libs/cas.war cas-overlay/

EXPOSE 8080 8443

ENV PATH $PATH:$JAVA_HOME/bin:.

WORKDIR cas-overlay
ENTRYPOINT ["java", "-server", "-noverify", "-Xmx2048M", "-jar", "cas.war"]
