#!/bin/bash
set -e

if [ "$1" = 'exim' ]; then
    if [ -n "$ETC_MAILNAME" ]
    then
        echo "$ETC_MAILNAME" > /etc/mailname
    fi

    # update-exim4.conf -v

    if [ "$(id -u)" = '0' ]; then
        mkdir -p /var/spool/exim4 /var/log/exim4 || :
        chown -R Debian-exim:Debian-exim /var/spool/exim4 /var/log/exim4 || :
        chown -R root:Debian-exim /etc/exim4/passwd.client || :
        chmod 0640 /etc/exim4/passwd.client || :
    fi
fi

exec "$@"
