import XCTest

@MainActor
class HomeworkUITestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        let orientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCTAssertTrue(["portrait", "landscape"].contains(orientation))
        XCUIDevice.shared.orientation = orientation == "landscape" ? .landscapeLeft : .portrait
    }
}
