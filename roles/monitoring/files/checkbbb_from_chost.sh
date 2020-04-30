!/bin/bash

BBBS=$(machinectl list | grep bbb | awk '{print $1}')

for h in $BBBS; do
	systemd-run --unit="checkmk_bbb" -M $h -- /usr/local/bin/checkbbb_for_chost.py > /dev/null 2>&1
done

# Wait for the units to finish
sleep 4

# Get results
sumM=0
sumAtt=0
sumVid=0
sumVoi=0
sumLis=0

for h in $BBBS; do
	# Check if unit has failed
	failed=$(systemctl -M $h is-failed checkmk_bbb)
	if [ "X$failed" == "Xfailed" ]; then
		echo "1 $h-bbbcheck - BBB Check from containerhost failed"
		systemctl -M $h reset-failed checkmk_bbb
	else
		echo "0 $h-bbbcheck - BBB Check from containerhost ok"
	fi

	if [ -f /var/lib/machines/$h/var/cache/checkbbb/overview ]; then
		cat /var/lib/machines/$h/var/cache/checkbbb/overview

		# Get stats from instances to add them up
		serversum=$(grep "\[ServerSum" /var/lib/machines/$h/var/cache/checkbbb/overview  | awk 'NR>1{print $1}' RS='[' FS=']' | head -n 1 | sed -e "s/ServerSum//")
		read -r -a statparts <<< "$serversum"
		meetings=$(echo ${statparts[0]} | cut -d: -f 2)
		attendees=$(echo ${statparts[1]} | cut -d: -f 2)
		videos=$(echo ${statparts[2]} | cut -d: -f 2)
		voice=$(echo ${statparts[3]} | cut -d: -f 2)
		listeners=$(echo ${statparts[4]} | cut -d: -f 2)
		sumM=$((sumM + meetings))
		sumAtt=$((sumAtt + attendees))
		sumVid=$((sumVid + videos))
		sumVoi=$((sumVoi + voice))
		sumLis=$((sumLis + listeners))
	fi
done

echo "0 bbb-containersum numMeetings=$sumM|numAttendees=$sumAtt|numWithVoice=$sumVoi|numWithVideo=$sumVid|numListeners=$sumLis [ContainerSum M:$sumM Att:$sumAtt Vid:$sumVid Voi:$sumVoi Lis:${sumLis}]"

