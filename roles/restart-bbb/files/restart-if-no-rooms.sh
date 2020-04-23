#!/bin/bash
#
# All instances with an uptime larger than AGE (in seconds)
# will be restartet if there are no meetings running.
#
set -eu

AGE="${1:-0}"

STAMP="/var/log/bbb-restart-stamp"
BBBUPTIME=-1
[ -f "$STAMP" ] && BBBUPTIME="$(( $(date +%s) - $(date +%s -d $(cat $STAMP)) ))"

if [ $BBBUPTIME -gt $AGE -o $BBBUPTIME -lt 0 ] ; then
    /usr/local/bin/checkbbb_for_chost.py
    sleep 1

    numrooms=$(grep -o "numMeetings=[0-9]\+" /var/cache/checkbbb/overview | sed -e "s/numMeetings=//")

    if [ x$numrooms  == "x0" ]; then
        # restart
        bbb-conf --restart && echo "$(date --iso-8601='seconds')" > "$STAMP"
        echo "There were $numrooms rooms. BBB restarted"
    else
        echo "There were $numrooms rooms. BBB NOT restarted"
    fi
else
    echo "BBB uptime too small to restart."
fi
