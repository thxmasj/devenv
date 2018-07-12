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

ARG SETTINGS_DIR=/home/developer/.IntelliJIdea2018.1

## IntelliJ IDEA

ARG IDEA_VERSION=2018.1.6
ARG IDEA_SHA256=f3e86997a849aabec38c35f1678bcef348569ac5ae75c2db44df306362b12d26
RUN curl -fL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -o /tmp/idea.tgz \
    && echo $IDEA_SHA256 /tmp/idea.tgz | sha256sum -c - && tar -C /opt -xzvf /tmp/idea.tgz && mv /opt/idea* /opt/idea

## Go plugin

ARG GO_PLUGIN_VERSION=181.5087.39.204
ARG GO_PLUGIN_UPDATEID=46184
RUN curl -fL "https://plugins.jetbrains.com/files/9568/${GO_PLUGIN_UPDATEID}/intellij-go-${GO_PLUGIN_VERSION}.zip" -o /tmp/intellij-go.zip \
    && unzip /tmp/intellij-go.zip -d /opt/idea/plugins

## Docker plugin

ARG PLUGIN_BASE_URL=https://plugins.jetbrains.com/files
ARG DOCKER_PLUGIN_VERSION=181.5087.20
ARG DOCKER_PLUGIN_UPDATEID=46446
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

ENTRYPOINT ["/opt/idea/bin/idea.sh"]
