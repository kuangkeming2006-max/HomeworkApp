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
    name = project_name(root)
    expected = {f"{name}-unsigned.ipa", f"{name}-without-widgets-unsigned.ipa"}
    if len(assets) != 2 or {asset.name for asset in assets} != expected:
        raise RuntimeError("Expected the full and extension-free unsigned IPAs; release was not created")
    notes = Path("release-notes.md")
    notes.write_text(
        "Unsigned iPhoneOS build. Sign with your own free Apple account before installation.\n\n"
        "This draft does not certify physical-device installation or notification delivery. "
        "The standard IPA embeds the Live Activity widget. The without-widgets IPA keeps ordinary reminders "
        "and uses the same bundle identifier and data locations. "
        "See docs/INSTALLATION.md and the matching Apple CI run for validation evidence.\n")
    exists = subprocess.run(["gh", "release", "view", tag], stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL).returncode == 0
    if exists:
        subprocess.run(["gh", "release", "upload", tag, *map(str, assets), "--clobber"], check=True)
    else:
        subprocess.run(["gh", "release", "create", tag, *map(str, assets), "--verify-tag", "--draft",
                        "--title", f"{project_name(root)} {tag}", "--notes-file", str(notes)], check=True)


if __name__ == "__main__":
    main()
