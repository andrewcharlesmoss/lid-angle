#!/bin/zsh

set -euo pipefail

project_root=${0:A:h:h}
output_directory="${LID_ANGLE_LOCAL_OUTPUT_DIRECTORY:-$project_root/outputs/local}"
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

bash scripts/package-app.sh "$temporary_directory" "Lid Angle Local.app"

if [[ -d "$app_path" ]]; then
    previous_directory=$(mktemp -d "$output_directory/.lid-angle-local-previous.XXXXXX")
    mv "$app_path" "$previous_directory/Lid Angle Local.app"
fi

mv "$temporary_app" "$app_path"
rmdir "$temporary_directory"
temporary_directory=""

if [[ -n "$previous_directory" ]]; then
    rm -rf "$previous_directory"
    previous_directory=""
fi

print "Built $app_path"
