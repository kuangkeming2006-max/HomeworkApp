"""Publish build artifacts to a draft release without interpolating user input into a shell."""
import os
from pathlib import Path
import subprocess
from project_metadata import project_name
from validate_release import validate


def main():
    tag = os.environ["TAG"]
    validate(tag, os.environ["GITHUB_REF_TYPE"], os.environ["GITHUB_REF_NAME"])
    root = Path(__file__).resolve().parents[1]
    subprocess.run(["gh", "run", "download", os.environ["GITHUB_RUN_ID"], "--name",
                    "unsigned-device-" + os.environ["GITHUB_RUN_ATTEMPT"], "--dir", "release-assets"], check=True)
    assets = sorted(Path("release-assets").rglob("*.ipa"))
    if len(assets) != 1:
        raise RuntimeError("Expected one unsigned IPA; release was not created")
    notes = Path("release-notes.md")
    notes.write_text(
        "Unsigned iPhoneOS build. Sign with your own free Apple account before installation.\n\n"
        "This draft does not certify physical-device installation or notification delivery. "
        "See docs/INSTALLATION.md and the matching Apple CI run for validation evidence.\n")
    exists = subprocess.run(["gh", "release", "view", tag], stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL).returncode == 0
    if exists:
        subprocess.run(["gh", "release", "upload", tag, str(assets[0]), "--clobber"], check=True)
    else:
        subprocess.run(["gh", "release", "create", tag, str(assets[0]), "--verify-tag", "--draft",
                        "--title", f"{project_name(root)} {tag}", "--notes-file", str(notes)], check=True)


if __name__ == "__main__":
    main()
