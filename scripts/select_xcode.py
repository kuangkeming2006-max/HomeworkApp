"""Select the latest installed stable Xcode 27, retaining discovery output on failure."""
import glob
import json
import os
from pathlib import Path
import subprocess
import re


def main():
    artifacts = Path("artifacts")
    artifacts.mkdir(exist_ok=True)
    requested = os.environ.get("XCODE_VERSION", "latest-27")
    inventory = []
    candidates = []
    for app in sorted(glob.glob("/Applications/Xcode*.app")):
        developer = app + "/Contents/Developer"
        result = subprocess.run(["xcodebuild", "-version"],
                                env={**os.environ, "DEVELOPER_DIR": developer},
                                capture_output=True, text=True)
        inventory.append({"path": developer, "version": result.stdout, "error": result.stderr})
        match = re.search(r"^Xcode (\d+)\.(\d+)(?:\.(\d+))?$", result.stdout, re.MULTILINE)
        canonical = str(Path(app).resolve()).lower()
        if result.returncode == 0 and match and "beta" not in canonical and "candidate" not in canonical:
            version = tuple(int(part or 0) for part in match.groups())
            if (requested == "latest-27" and version[0] == 27) or match.group(0) == f"Xcode {requested}":
                candidates.append((version, developer))
    (artifacts / "xcode-inventory.json").write_text(json.dumps(inventory, indent=2))
    if not candidates:
        raise RuntimeError(f"Stable Xcode {requested} is not installed; inspect xcode-inventory.json")
    _, selected = sorted(candidates)[-1]
    with open(os.environ["GITHUB_ENV"], "a") as env:
        env.write(f"DEVELOPER_DIR={selected}\n")
    print(f"Selected {selected}")


if __name__ == "__main__":
    main()
