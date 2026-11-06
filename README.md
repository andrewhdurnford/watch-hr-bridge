# Watch HR Bridge

**Free and open source.** Apple Watch heart rate as a standard Bluetooth heart rate sensor, so Zwift (Mac, Windows, anything) pairs with it like a chest strap. No iPhone app, no ads, no account.

_Not affiliated with Zwift, Inc._

    Apple Watch --(BLE Heart Rate Service, 0x180D)--> Zwift

It is a watch-only app: no iPhone app, no relay. The watch runs an indoor-cycling `HKWorkoutSession` so heart rate is
measured continuously (about once a second), and advertises as **"Watch HR"**. Nothing is saved to Health.

## How it works (and the one risky bit)
`CBPeripheralManager` is marked unavailable on watchOS in the SDK headers, but the class exists at runtime.
`Watch/WatchBroadcaster.m` reaches it through the Objective-C runtime. It works on devices and in TestFlight builds,
but it is not a public API: Apple could remove it in a future watchOS, and App Review could reject it.

## Use
1. Open **HR Bridge** on the watch, tap ▶ (allow Health and Bluetooth the first time).
2. Zwift pairing screen > Heart Rate > **Watch HR**. The antenna count on the watch shows connected receivers.
3. Tap ■ when done (the green sensor lights stay on while the workout session runs).

## Build and install for yourself (free account)
    brew install xcodegen
    xcodegen generate
    xcodebuild -project WatchHRBridge.xcodeproj -scheme HRBridgeWatch -destination 'id=<WATCH_UDID>' \
      DEVELOPMENT_TEAM=<YOUR_TEAM_ID> -derivedDataPath build/dd \
      -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
    xcrun devicectl device install app --device <WATCH_UDID> build/dd/Build/Products/Debug-watchos/HRBridgeWatch.app
`<YOUR_TEAM_ID>` is your (personal or paid) Apple Developer team. Change the bundle ID in `project.yml` to one of your own.
Free-account builds expire after 7 days; reinstall. The watch must be unlocked, on wrist, on Wi-Fi.

### If Xcode is stuck on "Preparing for development" for the watch
Turn off any VPN (Tailscale broke the Mac-to-watch tunnel: the DDI mount hung with `kAMDReadError 0xe8000004`),
run `killall CoreDeviceService`, then reopen Xcode's device manager with the watch on wrist, awake and unlocked.

## TestFlight / App Store
Needs the paid Apple Developer Program. See `tools/archive.sh` (archive + upload) and `release/` (privacy policy
and App Store Connect text).

## Verify without Zwift
`tools/check_ble.sh` runs a Mac-side scanner that acts like Zwift and prints the bpm the watch broadcasts.

## Files
- `Watch/WatchBroadcaster.m` BLE Heart Rate service (0x180D / 0x2A37 / 0x2A38) via the Objective-C runtime
- `Watch/WorkoutManager.swift` workout session streaming HR, discarded on stop
- `Watch/WatchContentView.swift` UI (bpm, receiver count, ▶/■)
- `tools/make_icon.swift` generates the app icon

## License
MIT, see `LICENSE`.
