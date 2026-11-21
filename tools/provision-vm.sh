#!/bin/sh
# Provisions a freshly booted pearOS VM (vm-boot.sh) for running real SwiftUI apps: mounts the Mac's dyld + cache, copies the files that the real frameworks read from disk and that are
# not in the cache (from the Mac VM, lab only, never committed), installs our stand-ins and the Metal driver.  Run from the laptop.  Needs: the Mac VM (ssh 2229), the dev VM (ssh 2222) with
# the sources built by d/darwin/build.sh (/root/swd/out), IOKit/hid-stub (/root/hs/out), lsd-objc (Mac: /tmp/lsd/lsd-objc), the Metal driver bundle (Mac: /tmp/drv2/out).
K="ssh -p 2224 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost"
M="ssh -p 2229 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR alex@localhost"
D="ssh -p 2222 -i $HOME/fbsd-vm/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@localhost"
HERE="$(cd "$(dirname "$0")" && pwd)"
set -x
# 1. the Mac's dyld and cache (the rc script of the image's source tree; the CI image of 2026-11-19 has no wsbsd_macdeps)
cat "$HOME/pearOS/iso/overlay/etc-rc.d-wsbsd_macdeps" | $K 'cat > /tmp/macdeps.sh; chmod +x /tmp/macdeps.sh; /tmp/macdeps.sh onestart'
# 2. SystemVersion.plist of ours (facts only), data files, trampolines, resources of the frameworks (from the Mac VM)
$K 'cat > /tmp/big/sl/CoreServices/SystemVersion.plist' <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>ProductBuildVersion</key><string>25G332</string><key>ProductName</key><string>macOS</string>
<key>ProductUserVisibleVersion</key><string>26.7.2</string><key>ProductVersion</key><string>26.7.2</string><key>iOSSupportVersion</key><string>26.7</string>
</dict></plist>
PL
$M 'cd /usr/share && tar cf - icu langid' | $K 'mkdir -p /tmp/big/share && cd /tmp/big/share && tar xf - && mount -t nullfs /tmp/big/share/icu /usr/share/icu && mount -t nullfs /tmp/big/share/langid /usr/share/langid'
$M 'cd /usr/lib && tar cf - libobjc-trampolines.dylib libffi-trampolines.dylib' | $K 'cd /tmp/big/ul && tar xf -'
for f in AppKit SwiftUI SwiftUICore; do
  $M "cd /System/Library/Frameworks/$f.framework/Versions/*/Resources && tar cf - \$(ls | grep -v '\.lproj\$'; ls -d en.lproj Base.lproj 2>/dev/null)" | $K "V=\$(ls /System/Library/Frameworks/$f.framework/Versions | head -1); mkdir -p /tmp/big/sl/Frameworks/$f.framework/Versions/\$V/Resources && cd /tmp/big/sl/Frameworks/$f.framework/Versions/\$V/Resources && tar xf -"
done
$M 'cd /System/Library/PrivateFrameworks/SFSymbols.framework/Versions/A/Resources && tar cf - CoreGlyphs.bundle' | $K 'F=/tmp/big/sl/PrivateFrameworks/SFSymbols.framework; rm -rf $F/Versions/Current $F/Resources; mkdir -p $F/Versions/A/Resources && cd $F/Versions/A/Resources && tar xf - && ln -s A $F/Versions/Current && ln -s Versions/Current/Resources $F/Resources'
$M 'cd /System/Library/CoreServices/SystemAppearance.bundle && tar cf - Contents/Info.plist Contents/version.plist Contents/Resources 2>/dev/null' | $K 'mkdir -p /tmp/big/sl/CoreServices/SystemAppearance.bundle && cd /tmp/big/sl/CoreServices/SystemAppearance.bundle && tar xf -'
# 3. our stand-ins (built on the dev VM), lsd-objc and the Metal driver (built on the Mac VM)
$K 'mkdir -p /tmp/pe2 /tmp/big/sl/Extensions'
$D 'cd /root/swd/out && tar cf - wsbridge/wsbridge lsd-stub/out/lsd-stub carender-stub/out/carender-stub svc-stub/out/svc-stub' | $K 'cd /tmp && tar xf - && for f in wsbridge/wsbridge lsd-stub/out/lsd-stub carender-stub/out/carender-stub svc-stub/out/svc-stub; do cp /tmp/$f /tmp/pe2/; done'
$D 'cat /root/hs/out/hid-stub' | $K 'cat > /tmp/pe2/hid-stub; chmod +x /tmp/pe2/hid-stub'
$M 'cat /tmp/lsd/lsd-objc' | $K 'cat > /tmp/pe2/lsd-objc; chmod +x /tmp/pe2/lsd-objc'
$M 'cd /tmp/drv2/out && tar cf - PearMetalDriver.bundle' | $K 'cd /tmp/big/sl/Extensions && tar xf -'
echo "now: copy the app to /tmp/sw, the new WindowServer binary over the SkyLight Resources file, then sh pearos-stack.sh"
