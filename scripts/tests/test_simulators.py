import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from simulators import runtime_version, select_device


class SimulatorSelectionTests(unittest.TestCase):
    def testRuntimeNumbersUseNumericComparison(self):
        self.assertEqual(runtime_version("com.apple.CoreSimulator.SimRuntime.iOS-27-10"), (27, 10, 0))
        self.assertIsNone(runtime_version("com.apple.CoreSimulator.SimRuntime.tvOS-27-0"))

    def testFamilyAvailabilityAndMajorAreEnforced(self):
        fixture = {"devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
                {"name": "iPhone Test", "udid": "phone", "isAvailable": True},
                {"name": "iPad Test", "udid": "pad", "isAvailable": True},
                {"name": "iPhone Gone", "udid": "gone", "isAvailable": False}],
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
                {"name": "iPhone Old", "udid": "old", "isAvailable": True}]}}
        self.assertEqual(select_device(fixture, "phone")["udid"], "phone")
        self.assertEqual(select_device(fixture, "pad")["udid"], "pad")
        with self.assertRaises(RuntimeError):
            select_device(fixture, "pad", 28)
        with self.assertRaises(ValueError):
            select_device(fixture, "watch")

    def testMissingSimulatorsFailClearly(self):
        with self.assertRaisesRegex(RuntimeError, "No available iPhone"):
            select_device({}, "phone")

    def testLatestAvailableMinorWins(self):
        fixture = {"devices": {
            f"com.apple.CoreSimulator.SimRuntime.iOS-27-{minor}": [
                {"name": "iPhone Fixture", "udid": str(minor), "isAvailable": True}]
            for minor in (1, 2, 10)}}
        self.assertEqual(select_device(fixture, "phone")["udid"], "10")


if __name__ == "__main__":
    unittest.main()
