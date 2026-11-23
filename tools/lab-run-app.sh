#!/bin/sh
# sh lab-run-app.sh /System/Applications/Calculator.app [probe]: copies an application of the Mac VM (ssh 2229, lab only, never committed) to /root/apps of the lab VM (ssh 2224)
# and runs it as the user alex (log /tmp/app.log).  With "probe" the abort probe (tools/abortprobe.c: AttributeGraph's message and the frame addresses at abort()) is added to a copy
# of the binary as a dependency (Metal/tools/trace-device/add-dylib.py; /root/apps/lib/libabortprobe.dylib built on the Mac: sh abortprobe-build.sh).
M="ssh -p 2229 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR alex@localhost"
K="ssh -p 2224 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost"
app=$1; name=$(basename "$app" .app); bin="$name"
$M "cd $(dirname "$app") && tar cf - --exclude _CodeSignature $name.app" | $K "mkdir -p /root/apps && cd /root/apps && rm -rf $name.app && tar xf - && chown -R alex /root/apps"
if [ "$2" = probe ]; then
	scp -q -P 2224 -i "$HOME/fbsd-vm/id_ed25519" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost:/root/apps/$name.app/Contents/MacOS/$name /tmp/$name.fat
	python3 "$HOME/pearOS/Metal/tools/trace-device/add-dylib.py" /tmp/$name.fat /tmp/$name.probe /root/apps/lib/libabortprobe.dylib
	scp -q -P 2224 -i "$HOME/fbsd-vm/id_ed25519" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR /tmp/$name.probe root@localhost:/root/apps/$name.app/Contents/MacOS/${name}Probe
	$K "chmod 755 /root/apps/$name.app/Contents/MacOS/${name}Probe; chown alex /root/apps/$name.app/Contents/MacOS/${name}Probe"
	bin=${name}Probe
fi
$K "cd /tmp; su -m alex -c 'env HOME=/Users/alex timeout 60 /root/apps/$name.app/Contents/MacOS/$bin' > /tmp/app.log 2>&1; echo exit=\$? >> /tmp/app.log; tail -c 1500 /tmp/app.log"
