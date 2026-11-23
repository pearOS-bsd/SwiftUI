#!/bin/sh
# sh lab-try.sh LABEL [hello options...]: starts tests/hello on the lab VM (ssh 2224) up to three times (the first starts after a stack restart often do not paint) and prints the largest commit that WindowServer received ("commit of context N: M stream bytes"): the plain hello gives 28219, a window that never commits layers gives 1916.  Needs /var/log/WindowServer.log (the stack of full.sh) and a clean /tmp of the lab (tmpfs of 20 MB: remove /tmp/msgSends-*, /tmp/img, ca dumps first).
K="ssh -p 2224 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost"
lbl=$1; shift; res=""
for i in 1 2 3; do
	$K ': > /var/log/WindowServer.log'
	($K "pkill -9 -x hello; sleep 2; cd /tmp; su -m alex -c 'env HOME=/Users/alex timeout 45 /tmp/hello -dark YES $* > /tmp/hello.log 2>&1'" >/dev/null 2>&1 &)
	big=$($K 'sleep 12; until pgrep -x hello >/dev/null; do sleep 1; done; sleep 22; grep -a "commit of context" /var/log/WindowServer.log | sed "s/.*context \([0-9]*\): \([0-9]*\) stream.*/\2/" | sort -rn | head -1')
	res="$res $big"; [ "${big:-0}" -gt 5000 ] && break
	sleep 20
done
echo "$lbl:$res"
