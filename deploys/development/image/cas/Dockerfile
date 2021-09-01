FROM adoptopenjdk/openjdk11:alpine-slim AS overlay

RUN apk add --no-cache git \
  && mkdir -p /tmp/cas-overlay \
  && git clone -b 6.3 --single-branch https://github.com/apereo/cas-overlay-template.git /tmp/cas-overlay

RUN mkdir -p cas-overlay

RUN cp -r /tmp/cas-overlay/src/ /cas-overlay/src/ \
 && cp -r /tmp/cas-overlay/gradle/ /cas-overlay/gradle/ \
 && cp -r /tmp/cas-overlay/gradlew /tmp/cas-overlay/settings.gradle /tmp/cas-overlay/build.gradle /tmp/cas-overlay/gradle.properties /cas-overlay/

RUN rm -rf /tmp/cas-overlay

RUN mkdir -p ~/.gradle \
    && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties \
    && echo "org.gradle.configureondemand=true" >> ~/.gradle/gradle.properties \
    && cd cas-overlay \
    && chmod 750 ./gradlew \
    && ./gradlew --version;

COPY ./build/build.gradle /cas-overlay/

RUN cd cas-overlay \
    && ./gradlew clean build --parallel --no-daemon \
    && ./gradlew createKeystore


FROM adoptopenjdk/openjdk11:alpine-jre AS cas

LABEL "Organization"="Apereo"
LABEL "Description"="Apereo CAS"

RUN cd / \
    && mkdir -p /etc/cas/config \
    && mkdir -p cas-overlay;

COPY --from=overlay cas-overlay/build/libs/cas.war cas-overlay/
COPY --from=overlay etc/cas/thekeystore /etc/cas/thekeystore
COPY ./etc/cas/ /etc/cas/

EXPOSE 8080 8443

ENV PATH $PATH:$JAVA_HOME/bin:.

WORKDIR /cas-overlay
ENTRYPOINT ["java", "-server", "-noverify", "-Xmx2048M", "-jar", "cas.war"]