import copy
import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
import zipfile

PROJECT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("verify_release", PROJECT / "scripts/verify-release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseVerificationTests(unittest.TestCase):
    def setUp(self):
        with (PROJECT / "Resources/Info.plist").open("rb") as stream:
            self.metadata = plistlib.load(stream)
        self.version = self.metadata["CFBundleShortVersionString"]
        self.tag = "v" + self.version
        self.changelog = f"## Unreleased\n\n## {self.version} — 2026-08-31\n"

    def test_matching_source_passes(self):
        release.validate_release(self.metadata, self.tag, self.changelog)

    def test_tag_and_changelog_must_agree(self):
        with self.assertRaisesRegex(ValueError, "Release tag"):
            release.validate_release(self.metadata, "v9.9.9", self.changelog)
        with self.assertRaisesRegex(ValueError, "changelog"):
            release.validate_release(self.metadata, self.tag, "## Unreleased\n## 0.0.1 — 2020-01-01\n")

    def test_invalid_build_and_changed_deployment_target_are_rejected(self):
        for key, value in [("CFBundleVersion", ""), ("CFBundleVersion", "0"), ("LSMinimumSystemVersion", "15.0")]:
            with self.subTest(key=key, value=value):
                metadata = copy.copy(self.metadata)
                metadata[key] = value
                with self.assertRaises(ValueError):
                    release.validate_release(metadata, self.tag, self.changelog)

    def test_bundle_and_runtime_about_values_must_agree(self):
        with tempfile.TemporaryDirectory(prefix="lid-angle-release-test-") as temporary:
            app = Path(temporary) / "Test.app"
            contents = app / "Contents"
            binary = contents / "MacOS/LidAngleApp"
            binary.parent.mkdir(parents=True)
            (contents / "Info.plist").write_bytes(plistlib.dumps(self.metadata))
            runtime = {"version": self.version, "build": self.metadata["CFBundleVersion"], "identifier": self.metadata["CFBundleIdentifier"]}
            def write_runtime():
                binary.write_text("#!/bin/sh\nprintf '%s\\n' '" + json.dumps(runtime) + "'\n")
                binary.chmod(0o755)
            write_runtime()
            release.verify_bundle(self.metadata, app)
            runtime["build"] = "999"
            write_runtime()
            with self.assertRaisesRegex(ValueError, "Runtime About"):
                release.verify_bundle(self.metadata, app)
            metadata = copy.copy(self.metadata)
            metadata["CFBundleIdentifier"] = "wrong.identity"
            (contents / "Info.plist").write_bytes(plistlib.dumps(metadata))
            with self.assertRaisesRegex(ValueError, "Packaged Info.plist"):
                release.verify_bundle(self.metadata, app)

    def test_archive_metadata_and_required_assets_are_checked(self):
        with tempfile.TemporaryDirectory(prefix="lid-angle-archive-test-") as temporary:
            archive = Path(temporary) / "release.zip"
            def write_archive(metadata, omit_asset=False):
                with zipfile.ZipFile(archive, "w") as bundle:
                    prefix = "Lid Angle.app/Contents/"
                    bundle.writestr(prefix + "Info.plist", plistlib.dumps(metadata))
                    for relative in ["MacOS/LidAngleApp", "Resources/AppIcon.icns", "Resources/DoorCreak.wav"]:
                        if not (omit_asset and relative.endswith("wav")):
                            bundle.writestr(prefix + relative, b"fixture")
            write_archive(self.metadata)
            release.verify_archive(self.metadata, archive)
            modified = copy.copy(self.metadata)
            modified["CFBundleVersion"] = "999"
            write_archive(modified)
            with self.assertRaisesRegex(ValueError, "canonical metadata"):
                release.verify_archive(self.metadata, archive)
            write_archive(self.metadata, omit_asset=True)
            with self.assertRaises(KeyError):
                release.verify_archive(self.metadata, archive)


if __name__ == "__main__":
    unittest.main()
