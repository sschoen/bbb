#!/bin/bash

WARNING=80
CRITICAL=102

STATUS=3


kurentos=$(top -b -n 1 | grep kurento- | sort | awk '{print $1":"$9}')
maxpercentage=0

for l in $kurentos; do
	pid=$(echo $l | cut -d: -f1)
	percentage=$(echo $l | cut -d: -f2 | sed -e "s/\.//")
	bbbslice=$(systemctl status $pid 2> /dev/null | grep CGroup | grep bbb | cut -d@ -f2 | sed -e "s/\.service//" )

	numvideosonslice=$(sed -n 's/^.*|numWithVideo=\(.*\)|.*$/\1/p' /var/lib/machines/$bbbslice/var/cache/checkbbb/overview )
	fpercentage=$(bc <<< "scale=2; $percentage/10")
	hrstatus="$hrstatus [$bbbslice/$fpercentage/$numvideosonslice]"

	if [ $percentage -ge $maxpercentage ]; then
		maxpercentage=$percentage
		maxperccorrected=$(( maxpercentage / ( numvideosonslice * 33 + 1) ))

	fi

done

warnlevel=$(( WARNING * 10 ))
critlevel=$(( CRITICAL * 10 ))

if [ $maxperccorrected -gt $warnlevel ]; then
	STATUS=1
fi

if [ $maxperccorrected -gt $critlevel ]; then
	STATUS=2
fi

if [ $maxperccorrected -le $warnlevel ]; then
	STATUS=0
fi




maxpercentage=$(bc <<< "scale=2; $maxpercentage/10")
echo "$STATUS kurento-cpu max-kurento-cpu=$maxpercentage|max-kurento-cpu-videocorrected=$maxperccorrected $hrstatus"


