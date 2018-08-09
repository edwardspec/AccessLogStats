#!/bin/bash
###############################################################################
#
# Scan NCSA access log (produced by Apache or varnishncsa) for CIDR ranges of clients.
#
# Usage: scanAccessLog.sh <access.log
#
# Sample output (1 line):
# 76 66.249.66.154 GOOGLE 66.249.64.0/19 66.249.64.0 66.249.95.255
# ... which means:
#	There were 76 requests from 66.249.66.154,
#	which belongs to GOOGLE,
#	this IP is a part of 66.249.64.0/19 CIDR range,
#	first IP of this range is 66.249.64.0,
#	last IP of this range is 66.249.95.255.
#
###############################################################################

TMPFILE=$(mktemp)

# Only check each IP once. Also count the number of requests from each IP.
# Start with most popular IPs (to check misbehaving crawlers first).
awk '{print $1}' | sort | uniq -c | sort -r -n | while read LINE; do
	NUMBER_OF_REQUESTS=$(echo $LINE | awk '{print $1}')
	IP=$(echo $LINE | awk '{print $2}')

	# TODO: remember FIRST_IP_OF_RANGE/LAST_IP_OF_RANGE from previous checks,
	# so that we don't have to query Whois servers if $IP is within the range
	# which we already know about.
	whois $IP >$TMPFILE

	PROVIDER=$(grep -m 1 -i NetName $TMPFILE | awk '{print $2}')
	CIDR=$(grep -E -m 1 -i '(CIDR|route):' $TMPFILE | awk '{print $2}')

	IP_INTERVAL=$(grep -E -m 1 -i '(NetRange|inetnum):' $TMPFILE)
	FIRST_IP_OF_RANGE=$(echo $IP_INTERVAL | awk '{print $2}')
	LAST_IP_OF_RANGE=$(echo $IP_INTERVAL | awk '{print $4}')

	echo "${NUMBER_OF_REQUESTS} ${IP} ${PROVIDER} ${CIDR} ${FIRST_IP_OF_RANGE} ${LAST_IP_OF_RANGE}"
done

rm -f $TMPFILE
