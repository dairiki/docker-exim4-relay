#!/bin/bash
set -e

if [ "$1" = 'exim' ]; then
    if [ -n "$ETC_MAILNAME" ]
    then
        echo "$ETC_MAILNAME" > /etc/mailname
    fi

    if [ -n "$RELAY_NETS" ]
    then
        sed -i "s!^\\(dc_relay_nets=\\).*!\\1'$RELAY_NETS'!" \
            /etc/exim4/update-exim4.conf.conf
    fi

    if [ -n "$GLOBAL_RCPT_RATELIMIT" ]
    then
        cat > /etc/exim4/conf.d/main/01_local_global_ratelimit <<EOF
# Rate limit the total number or email recipients processed by MTA
acl_smtp_predata = \
    defer ratelimit = ${GLOBAL_RCPT_RATELIMIT}/per_rcpt/xx-global\n\
        message = 450 4.7.0 Sending rate limit exceeded\n\
        log_message = Sending rate limit exceeed ($sender_rate/$sender_rate_period)\n\
    accept
EOF
    else
        rm -f /etc/exim4/conf.d/main/01_local_global_ratelimit
    fi

    update-exim4.conf -v

    if [ "$(id -u)" = '0' ]; then
        mkdir -p /var/spool/exim4 /var/log/exim4 || :
        chown -R Debian-exim:Debian-exim /var/spool/exim4 /var/log/exim4 || :
        chown -R root:Debian-exim /etc/exim4/passwd.client || :
        chmod 0640 /etc/exim4/passwd.client || :
    fi
fi

exec "$@"
