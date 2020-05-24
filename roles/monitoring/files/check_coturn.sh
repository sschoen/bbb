#!/bin/bash

tmpfile=$(mktemp)
turnutils_uclient -t -n 1000 -m 10 -l 3037 -e 127.0.0.1 localhost > $tmpfile 2>&1 &

sleep 1

kill $! 2>/dev/null
wait $! 2>/dev/null

OKLINE=$(grep ERROR: $tmpfile | grep Allocation)
rm $tmpfile

if [ "x$OKLINE" != "x" ]; then
	echo "0  Coturn  -  Coturn answered."
else
	echo "2  Coturn  -  No answer from coturn."
fi


