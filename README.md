# Watch HR Bridge

Free, open-source watchOS app that turns your Apple Watch into a Bluetooth heart rate sensor, so Zwift and other cycling apps can pair with it like a chest strap. No iPhone app, no ads, no account.

_Not affiliated with Zwift, Inc._

    Apple Watch --(Bluetooth Heart Rate Service)--> Zwift, bike computers, other apps

## Use
1. Open **HR Bridge** on your Apple Watch and tap ▶. Allow Health and Bluetooth the first time.
2. In your cycling app, pair **Watch HR** as the heart rate source. The antenna count on the watch shows how many devices are connected.
3. Tap ■ when you finish.

The app runs a cycling workout session so the watch measures heart rate about once a second. Nothing is saved to Health, and nothing leaves your devices.

## Build
Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

    brew install xcodegen
    xcodegen generate
    xcodebuild -project WatchHRBridge.xcodeproj -scheme HRBridgeWatch \
      -destination 'id=<WATCH_UDID>' DEVELOPMENT_TEAM=<YOUR_TEAM_ID> \
      -derivedDataPath build/dd -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
    xcrun devicectl device install app --device <WATCH_UDID> \
      build/dd/Build/Products/Debug-watchos/HRBridgeWatch.app

Set your own bundle ID in `project.yml`. Builds signed with a free Apple ID expire after 7 days.

To check the broadcast without Zwift, run `tools/check_ble.sh` on a Mac. It scans like a cycling app and prints the heart rate it receives.

## Privacy
See [`release/privacy-policy.md`](release/privacy-policy.md).

## License
MIT. See [`LICENSE`](LICENSE).
