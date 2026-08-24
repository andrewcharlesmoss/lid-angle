# Lid Angle

A small native macOS app that shows the current angle of a MacBook lid.

It reads the built-in lid angle sensor through macOS IOKit HID feature reports:

- Vendor ID: `0x05AC`
- Product ID: `0x8104`
- Usage Page: `0x0020`
- Usage: `0x008A`
- Feature Report ID: `1`

## Download

Download the latest zip file from the GitHub Releases page, unzip it, and move `Lid Angle.app` to your Applications folder.

macOS may show a warning that Apple could not verify the app. This is expected because this release is not notarised by Apple. To open it, go to System Settings > Privacy & Security and choose Open Anyway for `Lid Angle.app`, or control-click the app and choose Open.

## Support

Lid Angle is free. If it helped you, made you laugh, or saved you measuring your MacBook with a protractor, you can support it here:

[Buy me a coffee](https://buymeacoffee.com/andrewcharlesmoss)

## Run locally

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

The sensor was introduced on the 2019 16-inch MacBook Pro and is present on various newer MacBook Pro and MacBook Air models. Compatibility depends on whether the Mac exposes the HID lid angle sensor to apps. If your Mac does not expose this HID device, the app will show an unavailable state rather than crashing.

## Documentation

- [Project instructions](AGENTS.md)
- [Changelog](CHANGELOG.md)
