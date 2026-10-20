"""Install one checksum-verified XcodeGen release. No Homebrew state dependency."""
import hashlib
import io
from pathlib import Path, PurePosixPath
import shutil
import urllib.request
import zipfile

VERSION = "2.46.0"
SHA256 = "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"
ROOT = Path(__file__).resolve().parents[1]


def unpack(payload, destination):
    # Preserve bin/ + share/: XcodeGen resolves its setting presets relative to bin/.
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        for entry in archive.infolist():
            path = PurePosixPath(entry.filename)
            if path.is_absolute() or ".." in path.parts:
                raise RuntimeError("Unsafe archive path")
            if entry.is_dir() or not entry.filename.startswith("xcodegen/"):
                continue
            relative = path.relative_to("xcodegen")
            if relative.parts[0] not in ("bin", "share"):
                continue
            target = destination.joinpath(*relative.parts)
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(entry) as source, target.open("wb") as output:
                shutil.copyfileobj(source, output)
    executable = destination / "bin/xcodegen"
    presets = destination / "share/xcodegen/SettingPresets/base.yml"
    if not executable.is_file() or not presets.is_file():
        raise RuntimeError("Release is missing the executable or required setting presets")
    executable.chmod(0o755)


def install():
    url = f"https://github.com/yonaskolb/XcodeGen/releases/download/{VERSION}/xcodegen.zip"
    with urllib.request.urlopen(url, timeout=120) as response:
        payload = response.read()
    if hashlib.sha256(payload).hexdigest() != SHA256:
        raise RuntimeError("XcodeGen download checksum mismatch")
    unpack(payload, ROOT / ".tools")
    print(f"Installed verified XcodeGen {VERSION}")


if __name__ == "__main__":
    install()
