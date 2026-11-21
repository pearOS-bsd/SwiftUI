#!/bin/sh
# on a Mac with the Swift toolchain: sh build.sh -> Hello.app (x86_64, the architecture of the pearOS cache)
set -e
cd "$(dirname "$0")"
rm -rf Hello.app; mkdir -p Hello.app/Contents/MacOS
swiftc -parse-as-library -target x86_64-apple-macosx14.0 hello.swift -o Hello.app/Contents/MacOS/Hello
cat > Hello.app/Contents/Info.plist <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Hello</string>
<key>CFBundleIdentifier</key><string>org.pearos.hello</string>
<key>CFBundleName</key><string>Hello</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PL
