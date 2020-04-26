FROM debian:buster-slim

# grab tini for signal processing and zombie killing
ENV TINI_VERSION v0.16.1
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates wget \
		gnupg dirmngr \
	; \
	dpkgArch="$(dpkg --print-architecture)"; \
	wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-$dpkgArch"; \
	wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5; \
	gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc; \
	chmod +x /usr/local/bin/tini; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	tini --version

RUN set -eux; \
	apt-get update; \
	apt-get install -y \
		exim4-daemon-light \
	; \
	rm -rf /var/lib/apt/lists/*

# https://blog.dhampir.no/content/exim4-line-length-in-debian-stretch-mail-delivery-failed-returning-message-to-sender
# https://serverfault.com/a/881197
# https://bugs.debian.org/828801
RUN echo "IGNORE_SMTP_LINE_LENGTH_LIMIT='true'" >> /etc/exim4/update-exim4.conf.conf

RUN set -eux; \
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

ENV ETC_MAILNAME smtp.dairiki.org

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 25
CMD ["exim", "-bd", "-q10m", "-v"]
