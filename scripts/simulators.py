"""Pure destination selection; never assume a device name or preinstalled runtime."""
import re


def runtime_version(identifier):
    match = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+)-(\d+)(?:-(\d+))?", identifier)
    return tuple(int(part or 0) for part in match.groups()) if match else None


def select_device(inventory, family, major=27, device_name=None):
    if family not in ("phone", "pad"):
        raise ValueError("Family must be phone or pad")
    prefix = "iPhone" if family == "phone" else "iPad"
    candidates = []
    for runtime, devices in inventory.get("devices", {}).items():
        version = runtime_version(runtime)
        if version is None or version[0] != major:
            continue
        for device in devices:
            if (device.get("isAvailable") and device.get("name", "").startswith(prefix)
                    and (device_name is None or device.get("name") == device_name)):
                candidates.append((version, device["name"], device["udid"], runtime))
    if not candidates:
        raise RuntimeError(f"No available {device_name or prefix} simulator on iOS {major}; inspect simulators.json")
    version, name, udid, runtime = sorted(candidates)[-1]
    return {"udid": udid, "name": name, "runtime": runtime, "version": list(version)}
