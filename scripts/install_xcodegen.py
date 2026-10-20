"""Install one checksum-verified XcodeGen release. No Homebrew state dependency."""
import hashlib
import io
from pathlib import Path
import shutil
import urllib.request
import zipfile

VERSION = "2.46.0"
SHA256 = "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"
ROOT = Path(__file__).resolve().parents[1]


def install():
    url = f"https://github.com/yonaskolb/XcodeGen/releases/download/{VERSION}/xcodegen.zip"
    with urllib.request.urlopen(url, timeout=120) as response:
        payload = response.read()
    if hashlib.sha256(payload).hexdigest() != SHA256:
        raise RuntimeError("XcodeGen download checksum mismatch")
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        matches = [entry for entry in archive.infolist()
                   if entry.filename.endswith("/bin/xcodegen") or entry.filename == "xcodegen"]
        if len(matches) != 1:
            raise RuntimeError("Expected exactly one XcodeGen executable in release")
        destination = ROOT / ".tools" / "xcodegen"
        destination.parent.mkdir(exist_ok=True)
        with archive.open(matches[0]) as source, destination.open("wb") as output:
            shutil.copyfileobj(source, output)
        destination.chmod(0o755)
    print(f"Installed verified XcodeGen {VERSION}")


if __name__ == "__main__":
    install()
