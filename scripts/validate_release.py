import os
import re


def validate(tag, ref_type, ref_name):
    if not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?", tag):
        raise ValueError("Use a semantic version tag such as v0.1.0")
    if ref_type != "tag" or ref_name != tag:
        raise ValueError("Dispatch the workflow on the matching existing tag to build the correct commit")


if __name__ == "__main__":
    validate(os.environ["TAG"], os.environ["REF_TYPE"], os.environ["REF_NAME"])
