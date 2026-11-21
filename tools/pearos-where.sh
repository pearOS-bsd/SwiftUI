# usage: where2.sh PROCESSPATTERN [N]  -> symbolised main-thread stack (kills the process with SIGILL)
K="-p 2224 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost"
timeout 60 ssh $K "dmesg -c >/dev/null; P=\$(pgrep -f '$1' | tail -1); kill -ILL \$P; sleep 3; dmesg | grep -E 'died of|frame [0-9]+:' | sed 's/.*return //; s/.*died of/died of/' | head -${2:-30} | tr '\n' ' '" > /tmp/fw.txt 2>&1
cd ~/.pear; python3 - <<'PY' > /tmp/frw.txt
import re
t=open('/tmp/fw.txt').read().replace('(stack','')
sl=0x1940C000
for a in re.findall(r'0x7ff[0-9a-f]+', t): print(hex(int(a,16)-sl))
PY
for a in $(head -${2:-30} /tmp/frw.txt); do ./bin/ipsw dyld a2f dsc/dyld_shared_cache_x86_64h $a 2>&1 | grep -E "0x[0-9a-f]+: " | head -1 | sed 's/(start.*//; s/^ *0x[0-9a-f]*: //' | cut -c1-110; done
