FROM debian:buster-slim

ENV ETC_MAILNAME smtp.dairiki.org

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		exim4-daemon-light \
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
