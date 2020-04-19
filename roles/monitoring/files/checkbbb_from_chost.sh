#!/bin/bash

BBBS=$(machinectl list | grep bbb | awk '{print $1}')

for h in $BBBS; do
	systemd-run --unit="checkmk_bbb" -M $h -- /usr/local/bin/checkbbb_for_chost.py > /dev/null 2>&1
done
sleep 1
for h in $BBBS; do
	# Check if unit has failed
	failed=$(systemctl -M $h is-failed checkmk_bbb)
	if [ "X$failed" == "Xfailed" ]; then 
		echo "1 $h-bbbcheck - BBB Check from containerhost failed"
		systemctl -M $h reset-failed checkmk_bbb
	else
		echo "0 $h-bbbcheck - BBB Check from containerhost ok"
	fi
	cat /var/lib/machines/$h/var/cache/checkbbb/overview
done
