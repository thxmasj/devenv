FROM openjdk:10.0.1-10

ARG IDEA_VERSION=2018.1.5
ARG IDEA_SHA256=010cec3753ec3ea9ad5fb96fa584a04a2682896291c21b2d9f575d8f473dc5d5

RUN curl -fL https://download-cf.jetbrains.com/idea/ideaIU-${IDEA_VERSION}.tar.gz -o /tmp/idea.tgz \
    && echo $IDEA_SHA256 /tmp/idea.tgz | sha256sum -c - && tar -C /opt -xzvf /tmp/idea.tgz && mv /opt/idea* /opt/idea

ENTRYPOINT ["/opt/idea/bin/idea.sh"]
