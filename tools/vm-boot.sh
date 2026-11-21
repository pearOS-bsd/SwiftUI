#!/bin/sh
# Starts the pearOS VM of the lab with room for the Mach stack and opens ssh.  Usage: sh vm-boot.sh ISO CACHE_IMG   (the image of a CI run + the MACCACHE disk of macdeps).
# The image's sshd cannot write host keys on its read-only root and the home is read-only too: sshd is started by hand through the serial console with a key in /tmp.
# After it: ssh -p 2224 -i ~/fbsd-vm/id_ed25519 root@localhost
set -e
ISO="${1:?ISO}"; CACHE="${2:?CACHE.img}"; WORK="${WORK:-$HOME/.pear/vm-swiftui}"; mkdir -p "$WORK"; rm -f "$WORK/serial.sock" "$WORK/monitor.sock"
HERE="$(cd "$(dirname "$0")" && pwd)"
( cd "$HOME/pearOS/iso" && RAM="${RAM:-12288}" CPUS="${CPUS:-6}" WORK="$WORK" DISPLAY_OPT=none RES=1920x1080 SSH_KEY="$HOME/fbsd-vm/id_ed25519.pub" nohup sh tools/run-vm.sh "$ISO" "$CACHE" > "$WORK/run.log" 2>&1 & )
sleep 6
python3 - "$WORK/serial.sock" "$(cat "$HOME/fbsd-vm/id_ed25519.pub")" <<'PY'
import socket, sys, time
sock, pub = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_UNIX); s.connect(sock); s.settimeout(1)
def rd(t):
    end = time.time() + t; b = b''
    while time.time() < end:
        try:
            d = s.recv(65536)
            if not d: break
            b += d
        except Exception: pass
    return b.decode('latin1')
buf = ''; t0 = time.time()
while 'login:' not in buf[-400:] and time.time() - t0 < 300: buf += rd(5)
s.send(b'\r'); rd(2); s.send(b'alex\r'); rd(2); s.send(b'pear\r'); rd(4)
for c in ['su -m root -c "ssh-keygen -q -t ed25519 -N \\"\\" -f /tmp/hk; echo \'%s\' > /tmp/ak; chmod 644 /tmp/ak; /usr/sbin/sshd -h /tmp/hk -o PermitRootLogin=yes -o AuthorizedKeysFile=/tmp/ak -o StrictModes=no; echo SSHD_RC=$?"' % pub]:
    s.send(c.encode() + b'\r'); print(rd(6)[-200:])
PY
