#!/bin/bash
# Archive the watch-only app (Watch HR Bridge) and upload it to App Store Connect (TestFlight).
#
# Usage: tools/archive.sh <TEAM_ID> [BUILD_NUMBER]
#   TEAM_ID       your paid Apple Developer team ID (developer.apple.com > Membership details)
#   BUILD_NUMBER  must be higher than any build you already uploaded (default: timestamp)
#
# Before the first run:
#   1. Enroll in the Apple Developer Program and sign in to Xcode with that Apple ID.
#   2. In App Store Connect create the app record: name "Watch HR Bridge",
#      platform watchOS, bundle ID com.andrewdurnford.watchhrbridge (register it first under
#      Certificates, Identifiers & Profiles > Identifiers, with the HealthKit capability).
#   3. Fill in the App Store Connect listing from release/app-store-listing.md.
set -euo pipefail
cd "$(dirname "$0")/.."

TEAM="${1:?usage: tools/archive.sh <TEAM_ID> [BUILD_NUMBER]}"
BUILD="${2:-$(date +%Y%m%d%H%M)}"
ARCHIVE=build/WatchHRBridge.xcarchive
EXPORT=build/export

xcodegen generate

rm -rf "$ARCHIVE" "$EXPORT"
xcodebuild -project WatchHRBridge.xcodeproj -scheme HRBridgeWatch -configuration Release \
  -destination 'generic/platform=watchOS' -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" CURRENT_PROJECT_VERSION="$BUILD" \
  archive

cat > build/ExportOptions.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>$TEAM</string>
  <key>signingStyle</key><string>automatic</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PL

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT" \
  -exportOptionsPlist build/ExportOptions.plist -allowProvisioningUpdates

echo "Uploaded build $BUILD. In App Store Connect > TestFlight, wait for processing,"
echo "then add testers. Testers install through the TestFlight app on their iPhone (it appears in the Watch app)."
