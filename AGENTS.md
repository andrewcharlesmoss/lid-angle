# Lid Angle project instructions

## Scope

Lid Angle is a native macOS app that reads the MacBook lid-angle HID sensor and
  presents the reading in the app and optional menu bar display.

## Commands

- Run locally with `swift run LidAngleApp`.
- Run a one-off sensor reading with `swift run LidAngleApp --once`.
- Build with `swift build -c release`.
- Run tests with `swift test`.

## Project-specific rules

- Preserve the macOS 14 deployment target and the IOKit HID sensor boundary.
- Keep unsupported-device behaviour safe and user-readable; do not assume the
  sensor exists on every Mac.

## Releases

- Before a release, follow the shared release checks and inspect the packaged
  app, About panel and bundle metadata.

## Verification

- Test both supported and unavailable sensor states where possible.
- Check the main window, menu bar display, display modes, sound and About panel
  after UI changes.
- Preserve the documented Gatekeeper and non-notarised release notice unless
  the distribution process changes.

## Git and deployment mapping

- The native app repository currently has only `main`; use `Local → Main` for
  app releases and keep packaging, signing and distribution as separate steps.
- The `marketing-site/` child project has its own tracked Sites hosting binding
  and currently also uses `main` as its production branch. Sites publishing is
  separate from committing and pushing.
- Verify the selected Sites target, exact source revision and deployment status
  before publishing the marketing site. Do not infer an automatic Git trigger
  from the hosting file; document a staging branch or target before introducing
  one.
