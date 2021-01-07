#!/bin/bash -e

if [[ $TZ ]]; then
    # Configure system timezone
    if [ -f "/usr/share/zoneinfo/$TZ" ]; then
	ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
	echo "$TZ" > /etc/timezone
    else
	echo "Unrecognized timezone TZ=$TZ" 1>&2
    fi
fi

if [[ -z $* ]]; then
    # Provide default CMD just in case it went missing
    set -- exim -bdf -q10m
fi

if [[ $1 =~ ^exim4?$ ]]; then
    # Configure exim
    cd /etc/exim4

    if [[ $ETC_MAILNAME ]]; then
	echo "$ETC_MAILNAME" > /etc/mailname
    fi

    if [[ $PASSWD_CLIENT ]]; then
	echo "$PASSWD_CLIENT" >> passwd.client
    fi
    if [[ $HUBBED_HOSTS ]]; then
	echo "$HUBBED_HOSTS" > hubbed_hosts
    fi
    if [[ $MANUAL_ROUTES ]]; then
	echo "$MANUAL_ROUTES" > manual_routes
    fi

    if [[ $GLOBAL_RCPT_RATELIMIT ]]; then
	echo "GLOBAL_RCPT_RATELIMIT = $GLOBAL_RCPT_RATELIMIT" \
	     >> conf.d/main/00_local_macros
    fi

    # Some update-exim4.conf.conf defaults
    dc_eximconfig_configtype=satellite
    dc_use_split_config=true
    : ${dc_local_interfaces:=}
    : ${dc_hide_mailname:=true}

    update-exim4.conf.conf-from-env
    update-exim4.conf -v

    # Run our script to stream exim's logs to stdout/stderr
    stream-exim4-logs
fi

exec "$@"
