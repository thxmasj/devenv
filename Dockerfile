FROM alpine:3.10.1 as idea
RUN apk add --no-cache curl unzip
ARG IDEA_VERSION=2019.2.1
RUN mkdir /idea \
    && curl -sSfL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz \
    | tar xz -C /idea --strip-components 1
ARG BASE_URL=https://plugins.jetbrains.com/files
ARG PLUGIN_DIR=/idea/plugins
RUN curl -sSfL "${BASE_URL}/6317/67665/lombok-plugin-0.26.2-2019.2.zip" -o /tmp/p1 && unzip /tmp/p1 -d ${PLUGIN_DIR}
RUN curl -sSfL "${BASE_URL}/9568/66978/intellij-go-192.6262.9.287.zip" -o /tmp/p2 && unzip /tmp/p2 -d ${PLUGIN_DIR}
RUN curl -sSfL "${BASE_URL}/631/67573/python.zip" -o /tmp/p3 && unzip /tmp/p3 -d ${PLUGIN_DIR}
RUN curl -sSfL "${BASE_URL}/4230/65772/BashSupport-1.7.12.192.zip" -o /tmp/p4 && unzip /tmp/p4 -d ${PLUGIN_DIR}
#RUN curl -sSfL "${BASE_URL}/7724/66972/Docker.zip" -o /tmp/p5 && unzip /tmp/p5 -d ${PLUGIN_DIR}

FROM alpine:3.10.1 as java8
RUN apk add --no-cache curl
RUN mkdir /java8 \
  && curl -sSfL https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u181-b13/OpenJDK8U-jdk_x64_linux_hotspot_8u181b13.tar.gz \
  | tar xz -C /java8 --strip-components 2

FROM alpine:3.10.1 as java11
RUN apk add --no-cache curl
RUN mkdir /java11 \
  && curl -sSfL https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11%2B28/OpenJDK11-jdk_x64_linux_hotspot_11_28.tar.gz \
  | tar xz -C /java11 --strip-components 2

FROM alpine:3.10.1 as java12
RUN apk add --no-cache curl
RUN mkdir /java12 \
  && curl -sSfL https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12.0.2%2B10/OpenJDK12U-jdk_x64_linux_hotspot_12.0.2_10.tar.gz \
  | tar xz -C /java12 --strip-components 1

FROM alpine:3.10.1 as go1_11
RUN apk add --no-cache curl
RUN \
  mkdir /go \
  && curl -sSfL https://dl.google.com/go/go1.11.13.linux-amd64.tar.gz | tar -xz -C /go --strip-components 1

FROM alpine:3.10.1 as go1_12
RUN apk add --no-cache curl
RUN \
  mkdir /go \
  && curl -sSfL https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz | tar -xz -C /go --strip-components 1

FROM alpine:3.10.1 as kubectl
RUN apk add --no-cache curl
RUN curl -sSfL https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl -o /kubectl

FROM ubuntu:19.04

# Avoid interactive prompt on setting up keyboard-configuration package
ENV DEBIAN_FRONTEND=noninteractive

# Avoid interactive prompt on GTK installation
RUN apt update && apt install -y tzdata
RUN echo "Europe/Oslo" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN apt update && apt install -y sudo curl unzip git vim bash-completion libxml2-utils socat net-tools \
    # Required by IDEA
    libxext6 libxrender1 libxtst6 libxi6 libfreetype6 \
    default-jdk maven \
    golang golang-glide go-bindata \
    python3-pip python-yaml \
    lsb-release software-properties-common apt-utils locales \
    # Required by JavaFX (IDEA, Markdown plugin)
    gtk3.0 \
    && pip3 install cryptography \
    && locale-gen en_US.UTF-8

RUN apt update && apt install -y nvidia-340 mesa-utils

ARG IDEA_MINOR_VERSION=2019.2
ARG SETTINGS_DIR=/home/developer/.IntelliJIdea${IDEA_MINOR_VERSION}

COPY --from=java8 /java8 /opt/java8
COPY --from=java11 /java11 /opt/java11
COPY --from=java12 /java12 /opt/java12
COPY --from=go1_11 /go /opt/go1.11
COPY --from=go1_12 /go /opt/go1.12
COPY --from=idea /idea/ /opt/idea/
COPY --from=kubectl /kubectl /usr/local/bin/kubectl

## Docker

ARG DOCKER_GPG_KEY_FINGERPRINT="9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88"
RUN curl -sSfL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-key fingerprint "${DOCKER_GPG_KEY_FINGERPRINT}" | grep "${DOCKER_GPG_KEY_FINGERPRINT}" \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt update \
    && apt install -y docker-ce

## Docker Compose

ARG DOCKER_COMPOSE_VERSION=1.22.0
RUN curl -sSfL https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && curl -sSfL https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

## Azure CLI

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && curl -sSfL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && apt update && apt install -y azure-cli

## MSSQL Tools

RUN curl -sSfL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSfL https://packages.microsoft.com/config/ubuntu/19.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt update && ACCEPT_EULA=y apt install -y mssql-tools unixodbc-dev
RUN curl -sSfL https://github.com/vippsas/mssql-jdbc/releases/download/v7.0.0-vipps-201812111300/mssql-jdbc-7.0.0.jre8.jar \
    -o $SETTINGS_DIR/config/jdbc-drivers/SQL\ Server/7.0.0/mssql-jdbc-7.0.0.jre8.jar \
    --create-dirs

RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer && \
    usermod -a -G docker developer

COPY idea/ ${SETTINGS_DIR}/
RUN chown -R developer:developer ${SETTINGS_DIR}
RUN chown -R developer:developer /opt/idea/plugins

USER developer
ENV HOME /home/developer
ENV PATH /opt/java8/bin:/opt/go1.11/bin:$PATH:/opt/mssql-tools/bin
ENV PS1 \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
VOLUME ${SETTINGS_DIR}/config/options/
WORKDIR $HOME
RUN mkdir -p bin && curl -sSfL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o bin/git-prompt.sh
COPY .bashrc .bashrc
ENV GIT_PS1_SHOWDIRTYSTATE 1
ENV GIT_PS1_SHOWSTASHSTATE 1
ENV GIT_PS1_SHOWUNTRACKEDFILES 1
ENV GIT_PS1_SHOWUPSTREAM auto
RUN git config --global user.name "Thomas Johansen" && \
    git config --global user.email "thxmasj@gmail.com" && \
    git config --global url.git@bitbucket.org:.insteadOf https://bitbucket.org/ && \
    git config --global url.git@github.com:vippsas/.insteadOf https://github.com/vippsas/

ENTRYPOINT ["/opt/idea/bin/idea.sh"]
