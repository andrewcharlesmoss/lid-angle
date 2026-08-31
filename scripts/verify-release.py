#!/usr/bin/env python3
"""Check source, packaged and runtime release metadata without changing them."""
import argparse
import json
from pathlib import Path
import plistlib
import re
import subprocess
import zipfile

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def validate_release(metadata, tag, changelog):
    version = metadata.get("CFBundleShortVersionString", "")
    build = metadata.get("CFBundleVersion", "")
    if not isinstance(version, str) or not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Release version must contain major.minor.patch")
    if not isinstance(build, str) or not re.fullmatch(r"[1-9]\d*", build):
        raise ValueError("Build number must be a positive integer")
    if tag != f"v{version}":
        raise ValueError(f"Release tag {tag!r} does not match version {version}")
    releases = re.findall(r"^## (\d+\.\d+\.\d+) — \d{4}-\d{2}-\d{2}$", changelog, re.MULTILINE)
    if not releases or releases[0] != version:
        raise ValueError("Latest released changelog entry does not match the project version")
    if metadata.get("LSMinimumSystemVersion") != "14.0":
        raise ValueError("The supported macOS deployment target must remain 14.0")
    identifier = metadata.get("CFBundleIdentifier", "")
    if not isinstance(identifier, str) or not re.fullmatch(r"[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+", identifier):
        raise ValueError("A valid canonical bundle identifier is required")
    if metadata.get("CFBundleExecutable") != "LidAngleApp":
        raise ValueError("Unexpected app executable")


def verify_bundle(metadata, app):
    with (app / "Contents/Info.plist").open("rb") as stream:
        bundled = plistlib.load(stream)
    if bundled != metadata:
        raise ValueError("Packaged Info.plist differs from canonical release metadata")
    binary = app / "Contents/MacOS" / metadata["CFBundleExecutable"]
    runtime = subprocess.run([str(binary), "--release-metadata"], check=True, capture_output=True, text=True, timeout=10)
    expected = {
        "version": metadata["CFBundleShortVersionString"],
        "build": metadata["CFBundleVersion"],
        "identifier": metadata["CFBundleIdentifier"],
    }
    if json.loads(runtime.stdout) != expected:
        raise ValueError("Runtime About metadata differs from packaged metadata")


def verify_archive(metadata, archive):
    with zipfile.ZipFile(archive) as bundle:
        info_names = [name for name in bundle.namelist() if name.endswith(".app/Contents/Info.plist") and not name.startswith("__MACOSX/")]
        if len(info_names) != 1 or plistlib.loads(bundle.read(info_names[0])) != metadata:
            raise ValueError("ZIP must contain exactly one app with canonical metadata")
        contents = info_names[0].removesuffix("Info.plist")
        for relative in ["MacOS/LidAngleApp", "Resources/AppIcon.icns", "Resources/DoorCreak.wav"]:
            if not bundle.getinfo(contents + relative).file_size:
                raise ValueError(f"ZIP is missing required app content: {relative}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--app", type=Path)
    parser.add_argument("--archive", type=Path)
    args = parser.parse_args()
    try:
        with (PROJECT_ROOT / "Resources/Info.plist").open("rb") as stream:
            metadata = plistlib.load(stream)
        validate_release(metadata, args.tag, (PROJECT_ROOT / "CHANGELOG.md").read_text())
        if args.app:
            verify_bundle(metadata, args.app.resolve())
        if args.archive:
            verify_archive(metadata, args.archive)
    except (ValueError, OSError, KeyError, plistlib.InvalidFileException, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Release verification failed: {error}\n")
    print(f"Verified {args.tag}, build {metadata['CFBundleVersion']}, {metadata['CFBundleIdentifier']}")


if __name__ == "__main__":
    main()
