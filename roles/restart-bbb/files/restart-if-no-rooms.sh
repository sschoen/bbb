#!/bin/bash

/usr/local/bin/checkbbb_for_chost.py

sleep 1

numrooms=$(grep -o "numMeetings=[0-9]\+" /var/cache/checkbbb/overview | sed -e "s/numMeetings=//")

if [ x$numrooms  == "x0" ]; then
        # restart
        bbb-conf --restart
        echo "There were $numrooms rooms. BBB restarted"
else
        echo "There were $numrooms rooms. BBB NOT restarted"
fi

