#!/bin/bash

BBBS=$(machinectl list | grep bbb | awk '{print $1}')

for h in $BBBS; do
	systemd-run -M $h -- /usr/local/bin/checkbbb_for_chost.py > /dev/null 2>&1
done
sleep 1
for h in $BBBS; do
	cat /var/lib/machines/$h/var/cache/checkbbb/overview
done
