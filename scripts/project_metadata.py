"""Resolve template-style project metadata from the canonical project.yml."""
from pathlib import Path
import re


def project_name(root):
    content = (Path(root) / "project.yml").read_text()
    match = re.search(r"^name:\s*([A-Za-z][A-Za-z0-9_]*)\s*$", content, re.MULTILINE)
    if not match:
        raise ValueError("project.yml must have an unquoted alphanumeric top-level name")
    return match.group(1)
