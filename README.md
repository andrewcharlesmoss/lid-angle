# Lid Angle App

A small native macOS app that shows the current angle of a MacBook Pro lid.

It reads the built-in lid angle sensor through macOS IOKit HID feature reports:

- Vendor ID: `0x05AC`
- Product ID: `0x8104`
- Usage Page: `0x0020`
- Usage: `0x008A`
- Feature Report ID: `1`

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
