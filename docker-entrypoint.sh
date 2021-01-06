#!/bin/bash -e

# Some update-exim4.conf.conf defaults
dc_eximconfig_configtype=satellite
dc_use_split_config=true
: ${dc_local_interfaces:=}
: ${dc_hide_mailname:=true}

update_exim4_conf () {
    if [ -n "$ETC_MAILNAME" ]; then
	echo "$ETC_MAILNAME" > /etc/mailname
    fi

    rm -f /etc/exim4/conf.d/00_local_global-rcpt-ratelimit
    if [ -n "$GLOBAL_RCPT_RATELIMIT" ]; then
	# this triggers code in /etc/exim4/conf.d/01_local_ratelimit
	echo "GLOBAL_RCPT_RATELIMIT = $GLOBAL_RCPT_RATELIMIT" \
	     > /etc/exim4/conf.d/00_local_global-rcpt-ratelimit
    fi

    # Update the values of any dc_*='...' settings in exim4.conf.conf
    # with the value of any environment variables of the same name.
    local var args=()
    for var in $(sed -nE 's/^(dc_[a-z_]*)=.*$/\1/p' \
		     /etc/exim4/update-exim4.conf.conf)
    do
	if [ -v "${var}" ]; then
	    args+=(-e "s|^${var}=.*|${var}='${!var}'|")
	fi
    done

    sed -i "${args[@]}" /etc/exim4/update-exim4.conf.conf
    update-exim4.conf -v
}

create_log_fifo () {
    rm -f "$1"
    mkfifo -m 0600 "$1"
    cat <> "$1" &
    chown Debian-exim:Debian-exim "$1"
}

stream_exim4_logs () {
    # Get exim logs to STDOUT/STDERR
    #
    # Hack to work-around inability to open /dev/stdout /dev/stderr
    # directly when not root.
    # See https://github.com/moby/moby/issues/6880

    # mainlog & rejectlog to stdout
    create_log_fifo /var/log/exim4/mainlog
    ln -sf mainlog /var/log/exim4/rejectlog

    # paniclog to stderr
    create_log_fifo /var/log/exim4/paniclog 1>&2
}

# Provide default CMD just in case it went missing
[ -n "$*" ] || set -- exim -bdf -q10m

if [[ $1 =~ ^exim4?$ ]]; then
    chown -R Debian-exim:Debian-exim /var/spool/exim4

    sed -i '/^[^#]/,$ d' /etc/exim4/passwd.client
    echo "$PASSWD_CLIENT" >> /etc/exim4/passwd.client

    echo "$HUBBED_HOSTS" > /etc/exim4/hubbed_hosts

    update_exim4_conf

    stream_exim4_logs
fi

exec "$@"
