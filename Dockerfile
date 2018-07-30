FROM ubuntu:18.04

# Avoid interactive prompt on GTK installation
RUN apt update && apt install -y tzdata
RUN echo "Europe/Oslo" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN apt install -y sudo curl unzip git vim \
    # Required by IDEA
    libxext6 libxrender1 libxtst6 libxi6 libfreetype6 \
    default-jdk maven \
    golang golang-glide go-bindata \
    lsb-release software-properties-common \
	gtk3.0 # Required by JavaFX (IDEA, Markdown plugin)

ARG IDEA_MINOR_VERSION=2018.2
ARG SETTINGS_DIR=/home/developer/.IntelliJIdea${IDEA_MINOR_VERSION}

## Oracle Java
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer

## IntelliJ IDEA
ARG IDEA_VERSION=${IDEA_MINOR_VERSION}
ARG IDEA_SHA256=dbe4bdd1c4cbce6ec549e0375227d64ac072200b2a92c8766ccb1fcd2ec5a65f
RUN curl -fL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -o /tmp/idea.tgz \
    && echo $IDEA_SHA256 /tmp/idea.tgz | sha256sum -c - && tar -C /opt -xzvf /tmp/idea.tgz && mv /opt/idea* /opt/idea

ARG PLUGIN_BASE_URL=https://plugins.jetbrains.com/files

## Lombok plugin
ARG LOMBOK_PLUGIN_VERSION=0.19-2018.EAP
ARG LOMBOK_PLUGIN_UPDATEID=47623
RUN curl -fL "${PLUGIN_BASE_URL}/6317/${LOMBOK_PLUGIN_UPDATEID}/lombok-plugin-${LOMBOK_PLUGIN_VERSION}.zip" -o /tmp/intellij-lombok.zip \
    && unzip /tmp/intellij-lombok.zip -d /opt/idea/plugins

## Go plugin

ARG GO_PLUGIN_VERSION=182.3684.111.849
ARG GO_PLUGIN_UPDATEID=48153
RUN curl -fL "${PLUGIN_BASE_URL}/9568/${GO_PLUGIN_UPDATEID}/intellij-go-${GO_PLUGIN_VERSION}.zip" -o /tmp/intellij-go.zip \
    && unzip /tmp/intellij-go.zip -d /opt/idea/plugins

## Docker plugin

ARG DOCKER_PLUGIN_VERSION=182.3684.90
ARG DOCKER_PLUGIN_UPDATEID=48047
RUN curl -fL "${PLUGIN_BASE_URL}/7724/${DOCKER_PLUGIN_UPDATEID}/Docker-${DOCKER_PLUGIN_VERSION}.zip" -o /tmp/intellij-docker.zip \
    && unzip /tmp/intellij-docker.zip -d /opt/idea/plugins

## Docker

ARG DOCKER_GPG_KEY_FINGERPRINT="9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88"
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-key fingerprint "${DOCKER_GPG_KEY_FINGERPRINT}" | grep "${DOCKER_GPG_KEY_FINGERPRINT}" \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt update \
    && apt install -y docker-ce

## Docker Compose

ARG DOCKER_COMPOSE_VERSION=1.21.2
RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && curl -L https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose


RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

COPY idea/ ${SETTINGS_DIR}/
RUN chown -R developer:developer ${SETTINGS_DIR}

USER developer
ENV HOME /home/developer
VOLUME ${SETTINGS_DIR}/config/options/

ENTRYPOINT ["/opt/idea/bin/idea.sh"]
