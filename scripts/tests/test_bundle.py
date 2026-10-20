from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from validate_bundle import validate_app_bundle
from package_ipa import package_ipa


class BundleTests(unittest.TestCase):
    def test_embedded_extension_and_deep_link_are_required(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / "HomeworkApp.app"
            extension = app / "PlugIns/HomeworkWidgets.appex"
            extension.mkdir(parents=True)
            info = dict(CFBundleIdentifier="com.kkm.homework", NSSupportsLiveActivities=True,
                        CFBundleURLTypes=[dict(CFBundleURLSchemes=["homework"])],
                        CFBundleVersion="2", CFBundleShortVersionString="0.2.0")
            widget = dict(CFBundleIdentifier="com.kkm.homework.widgets", CFBundleExecutable="HomeworkWidgets",
                          CFBundleVersion="2", CFBundleShortVersionString="0.2.0",
                          NSExtension=dict(NSExtensionPointIdentifier="com.apple.widgetkit-extension"))
            (app / "Info.plist").write_bytes(plistlib.dumps(info))
            (extension / "Info.plist").write_bytes(plistlib.dumps(widget))
            (extension / "HomeworkWidgets").write_bytes(b"synthetic")
            self.assertTrue(validate_app_bundle(app)["extensionEmbedded"])
            full = Path(directory) / "full.ipa"
            fallback = Path(directory) / "fallback.ipa"
            package_ipa(app, full)
            package_ipa(app, fallback, include_widgets=False)
            with zipfile.ZipFile(full) as archive:
                self.assertIn("Payload/HomeworkApp.app/PlugIns/HomeworkWidgets.appex/HomeworkWidgets", archive.namelist())
            with zipfile.ZipFile(fallback) as archive:
                self.assertFalse(any("/PlugIns/" in item for item in archive.namelist()))
                data = plistlib.loads(archive.read("Payload/HomeworkApp.app/Info.plist"))
                self.assertFalse(data["NSSupportsLiveActivities"])
                self.assertEqual(data["CFBundleIdentifier"], "com.kkm.homework")
            (extension / "HomeworkWidgets").unlink()
            with self.assertRaises(ValueError):
                validate_app_bundle(app)
