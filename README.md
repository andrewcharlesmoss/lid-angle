# Lid Angle App

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

The sensor was introduced on the 2019 16-inch MacBook Pro and is present on various newer MacBook Pro and MacBook Air models. Compatibility depends on whether the Mac exposes the HID lid angle sensor to apps. If your Mac does not expose this HID device, the app will show an unavailable state rather than crashing.


## Changelog

### 1.0.8 — 2026-08-17

- Corrects the version displayed in the About panel and release app metadata.

### 1.0.7 — 2026-08-17

- Updates the support link.

### 1.0.6 — 2026-07-25

- Stabilises stationary lid angle readings so they do not flicker between neighbouring degrees.
- Keeps larger lid movements responsive while confirming one-degree changes across consecutive sensor readings.

### 1.0.5 — 2026-07-01

- Fixes the menu bar Show Lid Angle action after the main window is closed.
- Keeps the main window available after closing it, so it can be reopened from the menu bar.
- Adds a Lid Angle app menu with Show, menu bar display, Support, GitHub, About, and Quit items.
- Adds a support link to the README.
- Centres the hinge dot in the Fully Open selector icon.
- Shows the copyright notice in the About panel.

### 1.0.4 — 2026-06-24

- Updates the app icon so the blue reference curve better matches the default Fully Open mode.

### 1.0.3 — 2026-06-18

- Adds a `0° Reference` label to clarify what the display selector controls.
- Renames Flat to Fully Open for clearer wording.
- Shows `Open` before the angle in the menu bar when using Fully Open mode.

### 1.0.2 — 2026-06-18

- Renames the window title to MacBook Lid Angle to include compatible MacBook Air models.
- Makes unsupported-device messaging model-neutral.
- Removes the redundant “degrees” label beneath readings that already use the degree symbol.

### 1.0.1 — 2026-06-13

- Makes Flat the default display mode.
- Shows `Closed` before the angle in the menu bar when using Closed mode.
- Prevents the app window from being resized.
- Tightens the MacBook visualiser spacing.
- Keeps the lid drawing a consistent length as the angle changes.
- Aligns the hinge with the start of the base.
- Shortens the visualiser base so it better matches the lid length.
- Adds clearer download instructions for macOS Gatekeeper warnings.

### 1.0.0 — 2026-06-12

- Initial release.
- Shows the live MacBook lid angle.
- Includes Closed and Flat display modes.
- Adds optional menu bar display and sound.
