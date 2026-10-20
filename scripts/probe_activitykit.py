"""Record actual SDK declarations and compile the scheduling API, without signing."""
from pathlib import Path
import subprocess


def main():
    output = Path("artifacts")
    output.mkdir(exist_ok=True)
    sdk = subprocess.check_output(["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True).strip()
    module = Path(sdk) / "System/Library/Frameworks/ActivityKit.framework/Modules/ActivityKit.swiftmodule"
    for interface in module.glob("*.swiftinterface"):
        if "private" not in interface.name:
            (output / interface.name).write_text(interface.read_text())
    source = output / "ActivityProbe.swift"
    source.write_text('''import ActivityKit
import Foundation
struct Probe: ActivityAttributes {
    struct ContentState: Codable, Hashable { var deadline: Date }
    var id: String
}
@MainActor func schedule() throws {
    let activity = try Activity<Probe>.request(
        attributes: Probe(id: "synthetic"),
        content: ActivityContent(state: .init(deadline: .now.addingTimeInterval(7200)), staleDate: nil),
        pushType: nil, style: .standard,
        alertConfiguration: AlertConfiguration(title: "Deadline", body: "One hour left", sound: .default),
        start: .now.addingTimeInterval(3600))
    if activity.activityState == .pending { print("Pending") }
}
''')
    result = subprocess.run(["xcrun", "swiftc", "-typecheck", "-warnings-as-errors", "-sdk", sdk,
                             "-target", "arm64-apple-ios26.0", str(source)], capture_output=True, text=True)
    (output / "activity-typecheck.log").write_text(result.stdout + result.stderr)
    print(result.stdout + result.stderr)
    result.check_returncode()


if __name__ == "__main__":
    main()
