#!/bin/bash
set -e

if [ "$1" = 'exim' ]; then
    if [ -n "$MAILNAME" ]
    then
        rm /etc/mailname
        echo "$MAILNAME" > /etc/mailname
    fi

    for line in $PASSWD_CLIENT
    do
        echo "$line" >> /etc/exim4/passwd.client
    done

    # Use authentication when connecting to mail hosts listed
    # in /etc/exim4/hubbed_hosts
    sed -i '/^ *transport/ s/remote_smtp$/remote_smtp_smarthost/' \
        /etc/exim4/conf.d/router/150_exim4-config_hubbed_hosts

    update-exim4.conf -v

    if [ "$(id -u)" = '0' ]; then
        mkdir -p /var/spool/exim4 /var/log/exim4 || :
        chown -R Debian-exim:Debian-exim /var/spool/exim4 /var/log/exim4 || :
    fi

    set -- tini -- "$@"
fi

exec "$@"
