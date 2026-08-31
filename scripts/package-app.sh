#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_directory="${1:?Provide a packaging output directory}"
app_name="${2:-Lid Angle.app}"
case "$app_name" in */*|.|..) echo "App name must not contain a path" >&2; exit 1 ;; esac
app_path="$output_directory/$app_name"
if [[ -e "$app_path" ]]; then
    echo "Refusing to replace existing app: $app_path" >&2
    exit 1
fi
cd "$project_root"
binary_directory="$(swift build -c release --show-bin-path)"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp -X "$binary_directory/LidAngleApp" "$app_path/Contents/MacOS/LidAngleApp"
cp -X Resources/AppIcon.icns Resources/DoorCreak.wav "$app_path/Contents/Resources/"
cp -X Resources/Info.plist "$app_path/Contents/Info.plist"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict "$app_path"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
python3 scripts/verify-release.py --tag "${RELEASE_TAG:-v$version}" --app "$app_path"
echo "Packaged $app_path"
