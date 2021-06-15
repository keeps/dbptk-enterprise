FROM openjdk:11-jre-slim as buildwar
RUN cd /tmp \
  && apt-get update \
  && apt-get -y install git \
  && git clone -b 6.3 --single-branch https://github.com/apereo/cas-overlay-template.git cas-overlay \
  && mkdir -p /tmp/cas-overlay/src/main/webapp
WORKDIR /tmp/cas-overlay

COPY build/build.gradle /tmp/cas-overlay/build.gradle
RUN  ./gradlew clean build

FROM openjdk:11-jre-slim
RUN mkdir /etc/cas \
  && cd /etc/cas \
  && keytool -genkey -noprompt -keystore thekeystore -storepass changeit -keypass changeit -validity 3650 \
             -keysize 2048 -keyalg RSA -dname "CN=localhost, OU=MyOU, O=MyOrg, L=Somewhere, S=VA, C=US"
RUN if [ -r /etc/cas/config/certificate.pem ]; then \
       keytool -noprompt -importcert -keystore /etc/ssl/certs/java/cacerts -storepass changeit \
               -file /etc/cas/config/certificate.pem -alias "casclient"; \
    fi
WORKDIR /root
COPY --from=buildwar /tmp/cas-overlay/build/libs/cas.war .
COPY etc/cas /etc/cas

EXPOSE 8443
EXPOSE 8080
CMD [ "/usr/local/openjdk-11/bin/java", "-jar", "/root/cas.war" ]
