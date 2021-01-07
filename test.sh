#!/bin/bash -e

randhex () {
    perl -e 'print [0..9,a..f]->[rand 16] for 1..12'
}

mailq () {
    local host="$1"
    exim -bp -DSPOOLDIR="/mailspool/$host"
}

has_arrived () {
    local host="$1" recipient="$2"
    mailq "$host" | fgrep -q "$recipient"
}

wait_for_mail () {
    local host="$1" recipient="$2" tries=0

    echo -n "Checking for arrival of message to ${recipient} at ${host} ... "
    while ! has_arrived "$host" "$recipient"; do
	if (( tries++ > 10 )); then
	    echo "TIMED OUT!"
	    exit 1
	fi
	sleep 1
    done
    echo "OK"
}

recipient=user-$(randhex)@example.net
local_recipient=joe-$(randhex)@example.org

swaks -s relay -f me@example.org -t "$recipient"
swaks -s relay -f me@example.org -t "$local_recipient"


wait_for_mail msa "$recipient"
wait_for_mail hub "$local_recipient"

#mailq hub
