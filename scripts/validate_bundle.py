"""Validate the app/extension contract before packaging a free-signing input artifact."""
from pathlib import Path
import plistlib


def validate_app_bundle(app: Path):
    with (app / "Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    if info.get("CFBundleIdentifier") != "com.kkm.homework":
        raise ValueError("The existing app bundle identifier must be preserved")
    if info.get("NSSupportsLiveActivities") is not True:
        raise ValueError("Live Activities support is absent from the built app")
    schemes = [scheme for entry in info.get("CFBundleURLTypes", []) for scheme in entry.get("CFBundleURLSchemes", [])]
    if "homework" not in schemes:
        raise ValueError("Homework deep links are absent from the built app")
    extension = app / "PlugIns/HomeworkWidgets.appex"
    with (extension / "Info.plist").open("rb") as stream:
        widget = plistlib.load(stream)
    if widget.get("CFBundleIdentifier") != "com.kkm.homework.widgets":
        raise ValueError("Unexpected widget bundle identifier")
    if widget.get("NSExtension", {}).get("NSExtensionPointIdentifier") != "com.apple.widgetkit-extension":
        raise ValueError("Invalid WidgetKit extension declaration")
    for key in ("CFBundleShortVersionString", "CFBundleVersion"):
        if info.get(key) != widget.get(key):
            raise ValueError("App and extension versions must agree")
    executable = widget.get("CFBundleExecutable", "")
    if not executable or not (extension / executable).is_file():
        raise ValueError("Embedded widget executable is missing")
    return {"app": info["CFBundleIdentifier"], "widget": widget["CFBundleIdentifier"],
            "version": info.get("CFBundleShortVersionString"), "liveActivities": True,
            "deepLinkScheme": "homework", "extensionEmbedded": True}
