FROM ubuntu:18.04

# Avoid interactive prompt on GTK installation
RUN apt update && apt install -y tzdata
RUN echo "Europe/Oslo" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN apt update && apt install -y sudo curl unzip git vim bash-completion libxml2-utils socat net-tools \
    # Required by IDEA
    libxext6 libxrender1 libxtst6 libxi6 libfreetype6 \
    default-jdk maven \
    golang golang-glide go-bindata \
    python3-pip \
    lsb-release software-properties-common apt-utils locales \
    # Required by JavaFX (IDEA, Markdown plugin)
    gtk3.0 \
    && pip3 install cryptography \
    && locale-gen en_US.UTF-8

ARG IDEA_MINOR_VERSION=2018.2
ARG SETTINGS_DIR=/home/developer/.IntelliJIdea${IDEA_MINOR_VERSION}

## Adopt OpenJDK 8
RUN \
  mkdir /opt/java8 \
  && curl -sSfL https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u181-b13/OpenJDK8U-jdk_x64_linux_hotspot_8u181b13.tar.gz | sudo tar xz -C /opt/java8 --strip-components 2

## Adopt OpenJDK 11
RUN \
  mkdir /opt/java11 \
  && curl -sSfL https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11%2B28/OpenJDK11-jdk_x64_linux_hotspot_11_28.tar.gz | sudo tar xz -C /opt/java11 --strip-components 2

## IntelliJ IDEA
ARG IDEA_VERSION=${IDEA_MINOR_VERSION}.3-no-jdk
ARG IDEA_SHA256=4854bf25ba0816e387f8afa0b9e0257314bb311ffd88a5634d06430ba515d306
RUN curl -sSfL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -o /tmp/idea.tgz \
    && echo $IDEA_SHA256 /tmp/idea.tgz | sha256sum -c - && tar -C /opt -xzvf /tmp/idea.tgz && mv /opt/idea* /opt/idea

# IntelliJ IDEA plugins
COPY get-plugin /usr/local/bin
RUN get-plugin 6317 47623 lombok-plugin 0.19-2018.EAP
RUN get-plugin 9568 49205 intellij-go 182.4129.55.890
RUN get-plugin 7724 49638 Docker 182.4323.18
RUN get-plugin 631 49639 python 2018.2.182.4323.46

## Docker

ARG DOCKER_GPG_KEY_FINGERPRINT="9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88"
RUN curl -sSfL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-key fingerprint "${DOCKER_GPG_KEY_FINGERPRINT}" | grep "${DOCKER_GPG_KEY_FINGERPRINT}" \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    && apt update \
    && apt install -y docker-ce

## Docker Compose

ARG DOCKER_COMPOSE_VERSION=1.21.2
RUN curl -sSfL https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    && curl -sSfL https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

## Azure CLI

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && curl -sSfL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && apt update && apt install -y azure-cli

## MSSQL Tools

RUN curl -sSfL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -sSfL https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt update && ACCEPT_EULA=y apt install -y mssql-tools unixodbc-dev

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
ENV PATH /opt/java8/bin:$PATH:/opt/mssql-tools/bin
ENV PS1 \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
VOLUME ${SETTINGS_DIR}/config/options/
WORKDIR $HOME
RUN mkdir -p bin && curl -sSfL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o bin/git-prompt.sh
COPY .bashrc .bashrc
ENV GIT_PS1_SHOWDIRTYSTATE 1
ENV GIT_PS1_SHOWSTASHSTATE 1
ENV GIT_PS1_SHOWUNTRACKEDFILES 1
ENV GIT_PS1_SHOWUPSTREAM auto

ENTRYPOINT ["/opt/idea/bin/idea.sh"]
