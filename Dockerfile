FROM debian:buster-20201209-slim

LABEL org.label-schema.name="exim4-relay"
LABEL org.label-schema.vcs-url="https://git.dairiki.org/config/synology/"
LABEL org.label-schema.schema-version="1.0"
LABEL maintainer="Jeff Dairiki <dairiki@dairiki.org>"

# Tweakables
ENV dc_readhost=example.org
ENV dc_relay_nets=172.16.0.0/12
ENV dc_smarthost=smtp.example.org::587

ENV ETC_MAILNAME=
ENV GLOBAL_RCPT_RATELIMIT=100/1h
ENV HUBBED_HOSTS=
ENV PASSWD_CLIENT=

#
RUN set -eux && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
	exim4-daemon-light \
	# NB: scripts such as exiqgrep require perl-modules
	#perl-modules \
	&& \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  #
  # Hack up exim4-config.
  #
  # Use authentication when connecting to mail hosts listed
  # in /etc/exim4/hubbed_hosts
  #
  sed -i '/^ *transport/ s/remote_smtp$/remote_smtp_smarthost/' \
      	      /etc/exim4/conf.d/router/150_exim4-config_hubbed_hosts


VOLUME /var/spool/exim4
EXPOSE 25/tcp
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["exim", "-bdf", "-q10m"]

COPY etc /etc
COPY docker-entrypoint.sh /usr/local/bin/
