FROM alpine:3.6

# image metadata
LABEL image.name="k8s-kibana" \
      image.maintainer="Erik Maciejewski <mr.emacski@gmail.com>"

ENV REDACT_VERSION=0.1.0 \
    KIBANA_VERSION=5.5.1

RUN apk --no-cache add \
    nodejs \
    curl \
  # install redact
  && curl -L https://github.com/emacski/redact/releases/download/v$REDACT_VERSION/redact -o /usr/bin/redact \
  && chmod +x /usr/bin/redact \
  # install kibana
  && curl -L https://artifacts.elastic.co/downloads/kibana/kibana-$KIBANA_VERSION-linux-x86_64.tar.gz -o kibana-$KIBANA_VERSION-linux-x86_64.tar.gz \
  && tar -xf kibana-$KIBANA_VERSION-linux-x86_64.tar.gz \
  && mv kibana-$KIBANA_VERSION-linux-x86_64 kibana \
  && adduser -HD kibana kibana \
  # clean up
  && rm -rf kibana/node \
  && rm -f kibana-$KIBANA_VERSION-linux-x86_64.tar.gz \
  && apk del curl

COPY . /

EXPOSE 5601

# build metadata
ARG GIT_URL=none
ARG GIT_COMMIT=none
LABEL build.git.url=$GIT_URL \
      build.git.commit=$GIT_COMMIT

ENTRYPOINT ["redact", "entrypoint", \
            "--default-tpl-path", "/kibana.yml.redacted", \
            "--default-cfg-path", "/kibana/config/kibana.yml", \
            "--", \
            "kibana", "/kibana/bin/kibana"]
