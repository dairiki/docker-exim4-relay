
fatal () {
    echo "$*" 1>&2
    exit 1
}

# Run exim with spool directory from environment
mailq_at_host () {
    local spooldir="/spooldirs/$1"
    [[ -d $spooldir/msglog ]] || fatal "Spooldir for host $1 not found"

    exim -bp -DSPOOLDIR="$spooldir"
}

# List recipients of all messages in the mail queue
recipients_in_mailq () {
    mailq_at_host "$1" | awk '
    	 NF > 1 && $3 !~ /.*-.*-.*/ {
	     printf "Unexpected output from mailq: %s\n", $0 | "cat >&2";
	     exit 1;
	 }
    	 /^ / && NF == 1 { print $1; }
	 '
}

# wait for mail to recipient to arrive in mail queue
wait_for_mail_at_host () {
    local recipient="$1" host="$2"
    local tries=10
    local msgdesc="message to ${recipient} at ${host}"

    echo "Checking for arrival of ${msgdesc} ..." >&3
    while true; do
	if recipients_in_mailq "$host" | fgrep -q "$recipient"; then
	    echo "OK" >&3
	    break
	fi
	if ! (( --tries )); then
	    echo "TIMED OUT waiting for ${msgdesc}" 1>&2
	    return 1
	fi
	sleep 1
    done
}

# Generate random hex string
randhex () {
    local nbytes="${1:-6}"
    for ((i = 0; i < nbytes; i++)); do
	printf "%02x" $(( $RANDOM & 0xff ))
    done
    echo
}

