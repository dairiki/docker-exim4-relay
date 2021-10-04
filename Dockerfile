## -*- docker-image-name: "dairiki/exim4-relay" -*-

ARG DEBIAN_TAG=buster-20210927-slim

FROM debian:${DEBIAN_TAG} AS base

COPY auto-apt-proxy /usr/local/bin/
RUN set -ux && \
  auto-apt-proxy apt-get update && \
  auto-apt-proxy apt-get install -y --no-install-recommends \
        # auto-apt-proxy works better with busybox, which it can use
        # to find the default gateway
	busybox \
	exim4-daemon-light \
	# NB: scripts such as exiqgrep require perl-modules
	#perl-modules \
	tcputils \
	&& \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY sbin /usr/local/sbin
VOLUME /var/spool/exim4
WORKDIR /etc/exim4

HEALTHCHECK --interval=30s --timeout=10s CMD \
	set -- $(exim4 -bP -n daemon_smtp_ports) && \
	tcpconnect -r 127.0.0.1 "$1" </dev/null | grep '^220 '

################################################################
# Build a dummy MSA for testing only.
#
FROM base AS test-msa

# Install swaks which is used in the "sut" test service
RUN set -ux && \
  apt-get update && \
  auto-apt-proxy apt-get install -y --no-install-recommends swaks && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY etc_exim4-testmsa /etc/exim4
RUN set -ux && \
  echo "daemon_smtp_ports = 587" > conf.d/main/01_local_config && \
  echo "queue_only = true" >> conf.d/main/01_local_config && \
  update-exim4.conf.conf-from-env && \
  update-exim4.conf -v

EXPOSE 587/tcp
CMD ["stream-exim4-logs", "exim", "-bdf"]


################################################################
# Build the real relay image
FROM base AS exim4-relay

EXPOSE 25/tcp
ENTRYPOINT ["entrypoint.sh"]
CMD ["exim", "-bdf", "-q10m"]

COPY etc_exim4 /etc/exim4
COPY entrypoint.sh /usr/local/sbin/

# Tweakables used in entrypoint initialization:
#
# Domains matching dc_other_hostnames will be rewritten to
# dc_readhost in mail headers (env from, recipients, senders).
#
ENV \
  dc_other_hostnames=*.example.org \
  dc_readhost=example.org \
  dc_relay_nets=10.0.0.0/8;172.16.0.0/12;192.168.0.0/16 \
  dc_smarthost=smtp.example.org::587 \
  ETC_MAILNAME= \
  GLOBAL_RCPT_RATELIMIT=100/1h \
  HUBBED_HOSTS= \
  MANUAL_ROUTES= \
  PASSWD_CLIENT=

ARG SOURCE_VERSION SOURCE_COMMIT BUILD_DATE
LABEL \
  maintainer="Jeff Dairiki <dairiki@dairiki.org>" \
  org.label-schema.name="exim4-relay" \
  org.label-schema.vcs-url="https://git.dairiki.org/config/synology/" \
  org.label-schema.version="$SOURCE_VERSION" \
  org.label-schema.vcs-ref="$SOURCE_COMMIT" \
  org.label-schema.build-date="$BUILD_DATE" \
  org.label-schema.schema-version="1.0"

# FIXME: better HEALTHCHECK
# It should check for frozen and stale messages
