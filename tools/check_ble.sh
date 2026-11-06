#!/bin/bash
# Usage: tools/check_ble.sh [seconds]
# Builds a tiny Mac app that behaves like Zwift's HR scan and prints what the phone broadcasts.
set -e
cd "$(dirname "$0")"
APP=build/HRCheck.app
mkdir -p $APP/Contents/MacOS
swiftc -O hrcheck.swift -o $APP/Contents/MacOS/HRCheck
cat > $APP/Contents/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>HRCheck</string><key>CFBundleIdentifier</key><string>com.andrewdurnford.hrcheck</string><key>CFBundleName</key><string>HRCheck</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string>
<key>NSBluetoothAlwaysUsageDescription</key><string>Checks the HR Bridge broadcast.</string></dict></plist>
PL
codesign -s - --force $APP >/dev/null
rm -f /tmp/hrcheck.log
open -n $APP --args "${1:-60}"
echo "Running… watching /tmp/hrcheck.log (Ctrl-C to stop)"
sleep 2; tail -f /tmp/hrcheck.log
