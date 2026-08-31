#!/bin/zsh

set -euo pipefail

project_root=${0:A:h:h}
output_directory="$project_root/outputs/local"
app_path="$output_directory/Lid Angle Local.app"
temporary_directory=""
previous_directory=""

cleanup() {
    [[ -n "$temporary_directory" && -d "$temporary_directory" ]] && rm -rf "$temporary_directory"

    if [[ -n "$previous_directory" && -d "$previous_directory" && ! -d "$app_path" ]]; then
        mv "$previous_directory/Lid Angle Local.app" "$app_path"
    fi
}
trap cleanup EXIT

cd "$project_root"
swift build -c release

mkdir -p "$output_directory"
temporary_directory=$(mktemp -d "$output_directory/.lid-angle-local-build.XXXXXX")
temporary_app="$temporary_directory/Lid Angle Local.app"

mkdir -p "$temporary_app/Contents/MacOS" "$temporary_app/Contents/Resources"
cp -X "$project_root/.build/release/LidAngleApp" "$temporary_app/Contents/MacOS/LidAngleApp"
cp -X "$project_root/Resources/AppIcon.icns" "$temporary_app/Contents/Resources/AppIcon.icns"
cp -X "$project_root/Resources/DoorCreak.wav" "$temporary_app/Contents/Resources/DoorCreak.wav"

cat > "$temporary_app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Lid Angle</string>
    <key>CFBundleExecutable</key>
    <string>LidAngleApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.andrewmoss.lid-angle</string>
    <key>CFBundleName</key>
    <string>Lid Angle</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.8</string>
    <key>CFBundleVersion</key>
    <string>8</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

if [[ -d "$app_path" ]]; then
    previous_directory=$(mktemp -d "$output_directory/.lid-angle-local-previous.XXXXXX")
    mv "$app_path" "$previous_directory/Lid Angle Local.app"
fi

mv "$temporary_app" "$app_path"
rmdir "$temporary_directory"
temporary_directory=""

xattr -cr "$app_path"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict "$app_path"

if [[ -n "$previous_directory" ]]; then
    rm -rf "$previous_directory"
    previous_directory=""
fi

print "Built $app_path"
