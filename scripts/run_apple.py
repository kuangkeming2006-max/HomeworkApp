"""Apple CI driver. Every subprocess keeps its raw output; failures preserve diagnostics."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

from simulators import select_device
from project_metadata import project_name
from screenshots import png_dimensions

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"
APP_NAME = project_name(ROOT)


def run(command, log, check=True, extra_env=None, timeout=900):
    print("Running " + " ".join(str(part) for part in command), flush=True)
    with (ARTIFACTS / log).open("w") as output:
        try:
            result = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT,
                                    env={**os.environ, **(extra_env or {})}, timeout=timeout)
        except subprocess.TimeoutExpired:
            output.write(f"\nCommand exceeded {timeout} seconds\n")
            output.flush()
            if check:
                raise RuntimeError(f"Command timed out; inspect {log}") from None
            return 124
    if check and result.returncode:
        print((ARTIFACTS / log).read_text(errors="replace")[-24000:], flush=True)
        raise RuntimeError(f"Command failed ({result.returncode}); inspect {log}")
    return result.returncode


def collect_diagnostics(udid=None):
    if udid:
        run(["xcrun", "simctl", "spawn", udid, "log", "show", "--last", "10m", "--style", "compact",
             "--predicate", 'process == "HomeworkApp"'], "simulator-app.log", check=False, timeout=90)
    crash_source = Path.home() / "Library/Logs/DiagnosticReports"
    for report in crash_source.glob("*Homework*"):
        if report.is_file():
            target = ARTIFACTS / "crashes" / report.name
            target.parent.mkdir(exist_ok=True)
            shutil.copy2(report, target)
    result = ARTIFACTS / "Tests.xcresult"
    if result.exists():
        run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(result)],
            "test-summary.json", check=False, timeout=90)
        run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(result),
             "--output-path", str(ARTIFACTS / "screenshots")], "export-screenshots.log", check=False, timeout=90)
    build_log = ARTIFACTS / "xcodebuild.log"
    if build_log.exists():
        warnings = [line for line in build_log.read_text(errors="replace").splitlines() if "warning:" in line]
        (ARTIFACTS / "warnings.txt").write_text("\n".join(warnings))


def simulator(args):
    udid = None
    try:
        run(["xcodebuild", "-showsdks"], "sdks.log")
        run(["xcrun", "simctl", "list", "--json"], "simulator-inventory.json")
        run(["xcrun", "simctl", "list", "devices", "available", "--json"], "simulators.json")
        selected = select_device(json.loads((ARTIFACTS / "simulators.json").read_text()), args.family, args.runtime)
        selected.update({"appearance": args.appearance, "orientation": args.orientation,
                         "commit": os.environ.get("GITHUB_SHA"), "runner": os.environ.get("RUNNER_NAME"),
                         "developerDir": os.environ.get("DEVELOPER_DIR")})
        (ARTIFACTS / "device.json").write_text(json.dumps(selected, indent=2))
        udid = selected["udid"]
        run(["xcrun", "simctl", "boot", udid], "boot.log", check=False)
        run(["xcrun", "simctl", "bootstatus", udid, "-b"], "bootstatus.log", timeout=300)
        run(["xcrun", "simctl", "ui", udid, "appearance", args.appearance], "appearance.log")
        run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41",
             "--batteryState", "charged", "--batteryLevel", "100"], "statusbar.log", check=False)
        env = {"TEST_ORIENTATION": args.orientation}
        run(["xcodebuild", "test", "-project", f"{APP_NAME}.xcodeproj", "-scheme", APP_NAME,
             "-destination", f"platform=iOS Simulator,id={udid}", "-destination-timeout", "120",
             "-derivedDataPath", "DerivedData", "-resultBundlePath", str(ARTIFACTS / "Tests.xcresult"),
             "-parallel-testing-enabled", "NO", "CODE_SIGNING_ALLOWED=NO",
             "-test-timeouts-enabled", "YES", "-maximum-test-execution-time-allowance", "180",
             f"TEST_ORIENTATION={args.orientation}"], "xcodebuild.log", extra_env=env)
    finally:
        collect_diagnostics(udid)
    screenshots = sorted((ARTIFACTS / "screenshots").rglob("*.png"))
    if len(screenshots) < 3:
        raise RuntimeError("Expected PNG screenshots for all three primary pages")
    metadata = []
    for screenshot in screenshots:
        dimensions = png_dimensions(screenshot.read_bytes())
        if (dimensions["displayWidth"] > dimensions["displayHeight"]) != (args.orientation == "landscape"):
            raise RuntimeError(f"Screenshot orientation does not match requested {args.orientation}")
        metadata.append({"file": str(screenshot.relative_to(ARTIFACTS)), **dimensions})
    (ARTIFACTS / "screenshots.json").write_text(json.dumps(metadata, indent=2))


def device_build():
    try:
        run(["xcodebuild", "build", "-project", f"{APP_NAME}.xcodeproj", "-scheme", APP_NAME,
             "-configuration", "Release", "-sdk", "iphoneos", "-destination", "generic/platform=iOS",
             "-derivedDataPath", "DerivedData", "CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO"],
            "xcodebuild.log")
        app = ROOT / f"DerivedData/Build/Products/Release-iphoneos/{APP_NAME}.app"
        if not app.is_dir():
            raise RuntimeError("No device .app was produced")
        run(["file", str(app / APP_NAME)], "binary-architecture.log")
        target = ARTIFACTS / "unsigned-device"
        target.mkdir(exist_ok=True)
        with zipfile.ZipFile(target / f"{APP_NAME}-unsigned.ipa", "w", zipfile.ZIP_DEFLATED) as archive:
            for source in sorted(app.rglob("*")):
                if source.is_file():
                    archive.write(source, f"Payload/{APP_NAME}.app/" + source.relative_to(app).as_posix())
        shutil.make_archive(str(target / f"{APP_NAME}-unsigned-app"), "zip", app.parent, app.name)
        shutil.copy2(ROOT / "docs/INSTALLATION.md", target / "INSTALLATION.md")
    finally:
        collect_diagnostics()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["simulator", "device"])
    parser.add_argument("--family", choices=["phone", "pad"], default="phone")
    parser.add_argument("--appearance", choices=["light", "dark"], default="light")
    parser.add_argument("--orientation", choices=["portrait", "landscape"], default="portrait")
    parser.add_argument("--runtime", type=int, default=27)
    args = parser.parse_args()
    ARTIFACTS.mkdir(exist_ok=True)
    if args.mode == "device":
        device_build()
    else:
        simulator(args)


if __name__ == "__main__":
    main()
