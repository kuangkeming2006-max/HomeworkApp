"""Create unsigned Payload archives, including an optional extension-free signing fallback."""
from pathlib import Path
import plistlib
import zipfile


def package_ipa(app: Path, target: Path, include_widgets=True):
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for source in sorted(app.rglob("*")):
            if not source.is_file():
                continue
            relative = source.relative_to(app)
            if not include_widgets and relative.parts[0] == "PlugIns":
                continue
            destination = f"Payload/{app.name}/" + relative.as_posix()
            if not include_widgets and relative.as_posix() == "Info.plist":
                info = plistlib.loads(source.read_bytes())
                info["NSSupportsLiveActivities"] = False
                archive.writestr(destination, plistlib.dumps(info, fmt=plistlib.FMT_BINARY))
            else:
                archive.write(source, destination)
