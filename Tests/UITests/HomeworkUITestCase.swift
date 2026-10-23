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

    override func tearDown() async throws {
        await MainActor.run {
            if let failures = testRun?.failureCount, failures > 0 {
                let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                screenshot.name = "Failure screen"; screenshot.lifetime = .keepAlways; add(screenshot)
                let app = XCUIApplication()
                if app.state == .runningForeground {
                    let tree = XCTAttachment(string: app.debugDescription)
                    tree.name = "Failure accessibility tree"; tree.lifetime = .keepAlways; add(tree)
                }
            }
        }
        try await super.tearDown()
    }

    @MainActor
    func selectCategory(_ name: String, app: XCUIApplication) {
        let segment = app.segmentedControls.buttons[name]
        if segment.exists { segment.tap() }
        else {
            app.buttons["assignments.filter"].tap()
            let option = app.buttons[name]
            XCTAssertTrue(option.waitForExistence(timeout: 5))
            // Let native activation resolve its hit point after menu presentation.
            // A provisional accessibility frame can be CGRect.null during animation.
            option.tap()
            // The host can move between the scrolling heading and inline toolbar.
            // Resolve it again after the native action has settled, rather than
            // retaining a predicate object for the previous accessibility element.
            XCTAssertEqual(app.buttons["assignments.filter"].value as? String, name)
        }
    }
}
