import struct
import sys
from pathlib import Path
import unittest
import zlib
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from screenshots import png_dimensions


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def metadata_fixture(orientation=None, endian="<"):
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1488, 2266, 8, 2, 0, 0, 0))
    if orientation is not None:
        exif = (b"II" if endian == "<" else b"MM") + struct.pack(endian + "HIH", 42, 8, 1)
        exif += struct.pack(endian + "HHIHHI", 0x0112, 3, 1, orientation, 0, 0)
        data += chunk(b"eXIf", exif)
    return data + chunk(b"IEND", b"")


class ScreenshotMetadataTests(unittest.TestCase):
    def testPlainPortraitRemainsPortrait(self):
        size = png_dimensions(metadata_fixture())
        self.assertEqual((size["displayWidth"], size["displayHeight"]), (1488, 2266))

    def testNativeRotatedScreenshotIsLandscapeInEitherByteOrder(self):
        for endian in ("<", ">"):
            for orientation in (5, 6, 7, 8):
                size = png_dimensions(metadata_fixture(orientation, endian))
                self.assertEqual((size["displayWidth"], size["displayHeight"]), (2266, 1488))
                self.assertEqual(size["pixelWidth"], 1488)

    def testUnrotatedMetadataDoesNotMasqueradeAsLandscape(self):
        for orientation in (1, 2, 3, 4):
            size = png_dimensions(metadata_fixture(orientation))
            self.assertLess(size["displayWidth"], size["displayHeight"])

    def testCorruptOrTruncatedMetadataIsRejected(self):
        with self.assertRaises(ValueError):
            png_dimensions(metadata_fixture(9))
        with self.assertRaises(ValueError):
            png_dimensions(metadata_fixture()[:30])
        with self.assertRaises(ValueError):
            png_dimensions(b"not a screenshot")
