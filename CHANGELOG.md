# Changelog

## Unreleased

## 1.0.8 — 2026-08-31

### Added

- Added a repeatable local app bundle for testing changes in the Dock without downloading a release.

### Changed

- Slightly enlarged the Dock icon to match the visible size of macOS app icons.
- Changed the menu bar reading to regular-weight text.

### Fixed

- Darkened the inactive display mode button in dark mode while preserving its light-mode appearance.
- Kept the window background in sync with the system appearance when switching between light and dark mode.

## 1.0.7 — 2026-08-17

### Changed

- Updated the support link and corrected the version displayed in the About panel and release app metadata.
- Restored the blue active state for the display mode selector.

## 1.0.6 — 2026-07-25

### Fixed

- Stabilised stationary lid angle readings so they do not flicker between neighbouring degrees.
- Kept larger lid movements responsive while confirming one-degree changes across consecutive sensor readings.

## 1.0.5 — 2026-07-01

### Added

- Added a Lid Angle app menu with Show, menu bar display, Support, GitHub, About, and Quit items.
- Added a support link to the README.

### Changed

- Centred the hinge dot in the Fully Open selector icon.
- Showed the copyright notice in the About panel.

### Fixed

- Fixed the menu bar Show Lid Angle action after the main window was closed.
- Kept the main window available after closing it, so it could be reopened from the menu bar.

## 1.0.4 — 2026-06-24

### Changed

- Updated the app icon so the blue reference curve better matched the default Fully Open mode.

## 1.0.3 — 2026-06-18

### Changed

- Added a `0° Reference` label to clarify what the display selector controls.
- Renamed Flat to Fully Open for clearer wording.
- Showed `Open` before the angle in the menu bar when using Fully Open mode.

## 1.0.2 — 2026-06-18

### Changed

- Renamed the window title to MacBook Lid Angle to include compatible MacBook Air models.
- Made unsupported-device messaging model-neutral.
- Removed the redundant “degrees” label beneath readings that already use the degree symbol.

## 1.0.1 — 2026-06-13

### Added

- Added clearer download instructions for macOS Gatekeeper warnings.

### Changed

- Made Flat the default display mode.
- Showed `Closed` before the angle in the menu bar when using Closed mode.
- Prevented the app window from being resized.
- Tightened the MacBook visualiser spacing.
- Kept the lid drawing a consistent length as the angle changed.
- Aligned the hinge with the start of the base.
- Shortened the visualiser base so it better matched the lid length.

## 1.0.0 — 2026-06-12

### Added

- Initial release.
- Showed the live MacBook lid angle.
- Included Closed and Flat display modes.
- Added optional menu bar display and sound.
