FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl libxext6 libxrender1 libxtst6 libxi6 libfreetype6 sudo default-jdk maven unzip golang git

ARG IDEA_VERSION=2018.1.5
ARG IDEA_SHA256=010cec3753ec3ea9ad5fb96fa584a04a2682896291c21b2d9f575d8f473dc5d5
ARG GO_PLUGIN_VERSION=181.5087.39.204
ARG GO_PLUGIN_UPDATEID=46184
ARG SETTINGS_DIR=/home/developer/.IntelliJIdea2018.1

RUN curl -fL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -o /tmp/idea.tgz \
    && echo $IDEA_SHA256 /tmp/idea.tgz | sha256sum -c - && tar -C /opt -xzvf /tmp/idea.tgz && mv /opt/idea* /opt/idea

RUN curl -fL "https://plugins.jetbrains.com/files/9568/${GO_PLUGIN_UPDATEID}/intellij-go-${GO_PLUGIN_VERSION}.zip" -o /tmp/intellij-go.zip \
    && unzip /tmp/intellij-go.zip -d /opt/idea/plugins

ARG PLUGIN_BASE_URL=https://plugins.jetbrains.com/files
ARG DOCKER_PLUGIN_VERSION=181.5087.20
ARG DOCKER_PLUGIN_UPDATEID=46446
RUN curl -fL "${PLUGIN_BASE_URL}/7724/${DOCKER_PLUGIN_UPDATEID}/Docker-${DOCKER_PLUGIN_VERSION}.zip" -o /tmp/intellij-docker.zip \
    && unzip /tmp/intellij-docker.zip -d /opt/idea/plugins

RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

COPY go.sdk.xml /home/developer/.IntelliJIdea2018.1/config/options/go.sdk.xml
RUN chown -R developer:developer ${SETTINGS_DIR}

USER developer
ENV HOME /home/developer

CMD "/opt/idea/bin/idea.sh"
