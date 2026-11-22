#!/bin/sh
# usage: runbp.sh ADDR... : starts akh2 as alex, waits for the solarium line, runs bp on it for 40 s, prints a summary and the first hits
pkill -9 bp; pkill -9 -x akh2; sleep 2
cd /tmp; rm -f /tmp/app.log; : > /tmp/app.log; chmod 666 /tmp/app.log
(su -m alex -c 'env HOME=/Users/alex timeout 150 /tmp/akh2 -NSTitlebarPocketEnabled NO -NSScrollPocketEnabled NO > /tmp/app.log 2>&1' &)
i=0; while [ $i -lt 100 ]; do grep -q 'AKH: >> solarium' /tmp/app.log 2>/dev/null && break; sleep 2; i=$((i+1)); done
sleep 1
P=$(pgrep -x akh2 | head -1)
echo "pid $P after $i waits"
[ -n "$P" ] || exit 1
BPCOUNT=1 BPSECS=40 timeout 50 /tmp/bp $P "$@" > /tmp/bp.out 2>/tmp/bp.err
cat /tmp/bp.err | head -3
awk '{print $3}' /tmp/bp.out | sort | uniq -c | sort -rn | head
head -14 /tmp/bp.out | cut -c1-150
grep -a 'AKH: display link' /tmp/app.log | cut -c1-100
