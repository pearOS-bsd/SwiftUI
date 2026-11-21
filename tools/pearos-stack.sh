#!/bin/sh
# The stack that a real SwiftUI app needs on the CI image + MACCACHE disk (2026-11-21), started by hand until wsbsd_macstack does it.  Run on the pearOS VM as root after wsbsd_macdeps (the Mac's dyld and cache mounted).
# The binaries are built by d/darwin/build.sh and IOKit/hid-stub/build.sh into /tmp/pe2 (copied there); lsd-objc is built on a Mac (d/darwin/lsd-objc).  Every process of the stack is killed first: a Mach-O process costs ~300 MB here and a second stack (stale hid-stub...) makes the kernel kill processes ("failed to reclaim memory").
pkill -9 -f MacOS/Calculator; for p in launchd notifyd wsbridge cfprefsd lsd-stub lsd-objc carender-stub svc-stub diskarb-stub hid-stub; do pkill -9 -x $p; pkill -9 -f "/$p " ; done; sleep 2
ps ax -o pid,command | grep -E "cfprefsd|notifyd|wsbridge|lsd|launchd" | grep -v grep | cut -c1-80
L=/tmp/pe2; export WS_SOCKET=/var/run/WindowServer.sock LSD_STORE=/tmp/lsdstore/store.csstore
set -- /usr/sbin/notifyd $L/wsbridge "/tmp/big/cfprefsd daemon" "/tmp/big/cfprefsd agent" $L/lsd-stub $L/lsd-objc $L/carender-stub "$L/svc-stub com.apple.PowerManagement.control" "$L/hid-stub" "$L/lsd-stub com.apple.coreservices.appleevents"
(cd /tmp; exec /sbin/launchd "$@") > /var/log/launchd-stack.log 2>&1 &
sleep 20
ps ax -o pid,stat,wchan,time,command | grep -E "cfprefsd|lsd-objc" | grep -v grep | cut -c1-90
grep -E "check-in|name type" /var/log/launchd-stack.log | grep -i -E "cfprefs|lsd" | head -8 | cut -c1-120
