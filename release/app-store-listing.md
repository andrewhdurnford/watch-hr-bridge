# App Store Connect — Watch HR Bridge

## App information
- **Name:** Watch HR Bridge
- **Subtitle (30 chars):** Apple Watch HR as a sensor
- **Platform:** watchOS (watch-only app, no iPhone app)
- **Bundle ID:** com.andrewdurnford.watchhrbridge
- **SKU:** watchhrbridge-1
- **Primary category:** Health & Fitness · **Secondary:** Sports
- **Price:** Free, no in-app purchases, no ads. Keep it that way: every "free" claim below must stay true.
- **Do not** put "free" (or any price wording) in the name, subtitle or keywords. Apple rejects that (guideline 2.3.7). Use it in the promo text and description only.
- **Age rating:** 4+ (no objectionable content)
- **Privacy policy URL:** _host release/privacy-policy.md somewhere public (GitHub Pages / gist) and paste the URL_
- **Support URL:** _same site or a GitHub repo_

## Promotional text (170 chars)
Completely free. Use your Apple Watch as a Bluetooth heart rate sensor for Zwift and other cycling apps. No chest strap, no ads, no account.

## Description
Watch HR Bridge turns your Apple Watch into a standard Bluetooth heart rate sensor, and it's completely free: no ads, no subscription, no in-app purchases, no account.

Start a session on your watch, pair "Watch HR" in Zwift (or any app that supports Bluetooth heart rate monitors), and your live heart rate shows up like it would from a chest strap.

• Works straight from the watch: nothing else to install or keep open
• Live heart rate, about once a second
• Works with Zwift and other cycling apps and bike computers that accept a Bluetooth heart rate sensor
• 100% free: no ads, no subscription, no in-app purchases
• Nothing is saved to Health, and nothing leaves your devices: no account, no tracking

How it works
1. Open HR Bridge on your Apple Watch and tap ▶.
2. In your cycling app, choose "Watch HR" under Heart Rate.
3. Ride. Tap ■ when you finish.

Good to know
• Starting a session runs a workout on your watch, so the green sensor lights stay on and your watch battery is used like any other workout. Tap ■ to stop.
• Not affiliated with Zwift, Inc. Zwift is a trademark of its owner; it's mentioned only to describe compatibility.

## Keywords (100 chars)
heart rate,watch,bluetooth,HRM,cycling,bike,indoor,trainer,sensor,strap,monitor,broadcast,virtual,ride

## What's New (1.0)
First release.

## Screenshots needed
- Apple Watch: 3 screenshots (idle, running with bpm and receivers, stopped), at the sizes App Store Connect asks for
  (largest watch size). Take them from the Watch simulator (Cmd+S) or the device.

## App Privacy ("nutrition label")
- Data collection: **Data Not Collected.** (Heart rate is processed on-device and transmitted over Bluetooth only to devices the user connects; it is never sent to the developer.)
- Tracking: **No.**

## Export compliance
- Uses encryption: **No** (ITSAppUsesNonExemptEncryption = NO is already set in the app).

## App Review notes (paste into "Notes")
This app shares live Apple Watch heart rate as a standard Bluetooth Low Energy Heart Rate sensor (GATT service 0x180D) so cycling apps like Zwift can use it.

To test without Zwift: install on an Apple Watch (via an iPhone with TestFlight), open "HR Bridge" on the watch, allow Health and Bluetooth access, tap ▶. A BLE scanner app (for example LightBlue or nRF Connect) will show a peripheral named "Watch HR" advertising Heart Rate (0x180D) with the 0x2A37 characteristic notifying. Tap ■ to stop.

HealthKit is used only to run a workout session that makes the watch measure heart rate continuously and to read the live heart rate from it. Nothing is written to Health (the workout is discarded when stopped) and no data leaves the device.

No account or login is required.
