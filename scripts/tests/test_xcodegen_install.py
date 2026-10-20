import io
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from install_xcodegen import unpack


def payload(files):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        for name, content in files.items():
            archive.writestr(name, content)
    return buffer.getvalue()


class XcodeGenInstallTests(unittest.TestCase):
    def testKeepsPresetsBesideBinaryInstallRoot(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            unpack(payload({"xcodegen/bin/xcodegen": b"executable",
                            "xcodegen/share/xcodegen/SettingPresets/base.yml": b"PRODUCT_NAME: value"}), root)
            self.assertTrue((root / "bin/xcodegen").is_file())
            self.assertEqual((root / "share/xcodegen/SettingPresets/base.yml").read_bytes(), b"PRODUCT_NAME: value")

    def testBinaryOnlyReleaseIsRejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(RuntimeError, "presets"):
                unpack(payload({"xcodegen/bin/xcodegen": b"binary"}), Path(folder))

    def testParentTraversalIsRejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(RuntimeError, "Unsafe"):
                unpack(payload({"xcodegen/../../outside": b"bad"}), Path(folder))
