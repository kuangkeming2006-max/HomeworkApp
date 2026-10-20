import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from validate_release import validate


class ReleaseValidationTests(unittest.TestCase):
    def testAllowsMatchingVersionTag(self):
        validate("v0.1.0-phase1", "tag", "v0.1.0-phase1")

    def testRejectsBranchOrDifferentTag(self):
        for args in [("v0.1.0", "branch", "main"), ("v0.1.0", "tag", "v0.2.0"),
                     ("--help", "tag", "--help"), ("v0.1.0;echo", "tag", "v0.1.0;echo")]:
            with self.assertRaises(ValueError):
                validate(*args)
