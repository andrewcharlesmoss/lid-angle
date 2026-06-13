# Lid Angle App

A small native macOS app that shows the current angle of a MacBook Pro lid.

It reads the built-in lid angle sensor through macOS IOKit HID feature reports:

- Vendor ID: `0x05AC`
- Product ID: `0x8104`
- Usage Page: `0x0020`
- Usage: `0x008A`
- Feature Report ID: `1`

## Download

Download the latest `lid-angle-v1.0.0.zip` file from the GitHub Releases page, unzip it, and move `Lid Angle.app` to your Applications folder.

macOS may show a warning that Apple could not verify the app. This is expected because this release is not notarised by Apple. To open it, go to System Settings > Privacy & Security and choose Open Anyway for `Lid Angle.app`, or control-click the app and choose Open.

## Run

```sh
swift run LidAngleApp
```

For a one-off Terminal reading:

```sh
swift run LidAngleApp --once
```

## Build

```sh
swift build -c release
```

The sensor was introduced on the 2019 16-inch MacBook Pro and is generally present on newer MacBooks. If your Mac does not expose this HID device, the app will show an unavailable state rather than crashing.
