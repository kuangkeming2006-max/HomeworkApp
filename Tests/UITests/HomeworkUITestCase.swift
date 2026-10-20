import XCTest

@MainActor
class HomeworkUITestCase: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        let orientation = ProcessInfo.processInfo.environment["TEST_ORIENTATION"] ?? "portrait"
        XCTAssertTrue(["portrait", "landscape"].contains(orientation))
        await MainActor.run {
            XCUIDevice.shared.orientation = orientation == "landscape" ? .landscapeLeft : .portrait
        }
    }

    @MainActor
    func selectCategory(_ name: String, app: XCUIApplication) {
        let segment = app.segmentedControls.buttons[name]
        if segment.exists { segment.tap() }
        else {
            app.buttons["assignments.filter"].tap()
            app.buttons[name].tap()
        }
    }
}
