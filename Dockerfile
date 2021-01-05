FROM debian:buster-slim

LABEL org.label-schema.name="exim4-relay"
LABEL org.label-schema.vcs-url="https://git.dairiki.org/config/synology/"
LABEL org.label-schema.schema-version="1.0"
LABEL maintainer="Jeff Dairiki <dairiki@dairiki.org>"

ENV ETC_MAILNAME smtp.dairiki.org
ENV RELAY_NETS   172.16.0.0/12;192.168.0.0/16;10.0.0.0/8;fd00::/8
ENV GLOBAL_RCPT_RATELIMIT 100/1h

# NB: scripts such as exiqgrep require perl-modules.
# I've added it here.  Remove it if you don't need the scripts to work.
#
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		exim4-daemon-light \
		perl-modules \
	; \
	apt-get clean; \
	rm -rf /var/lib/apt/lists/*; \
	mkdir -p /var/spool/exim4 /var/log/exim4; \
	chown -R Debian-exim:Debian-exim /var/spool/exim4 /var/log/exim4

VOLUME ["/var/spool/exim4", "/var/log/exim4"]

COPY update-exim4.conf.conf hubbed_hosts /etc/exim4/

# Use authentication when connecting to mail hosts listed
# in /etc/exim4/hubbed_hosts
RUN set -eux; \
    sed -i '/^ *transport/ s/remote_smtp$/remote_smtp_smarthost/' \
            /etc/exim4/conf.d/router/150_exim4-config_hubbed_hosts; \
    update-exim4.conf -v

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 25/tcp
CMD ["exim", "-bd", "-q10m", "-v"]
