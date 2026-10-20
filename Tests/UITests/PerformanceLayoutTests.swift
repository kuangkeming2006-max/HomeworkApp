import XCTest

@MainActor
final class PerformanceLayoutTests: HomeworkUITestCase {
    func testScrollingHundredsOfTasksRemainsInteractive() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-performance"]; app.launch()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        let list = app.descendants(matching: .any).matching(identifier: "assignments.list").firstMatch
        let start = Date()
        for _ in 0..<3 { list.swipeUp() }
        for _ in 0..<3 { list.swipeDown() }
        print("PERFORMANCE UI automation: six scroll gestures / 600 synthetic assignments = \(Date().timeIntervalSince(start)) seconds (includes automation waits, not frame timing)")
        XCTAssertTrue(app.buttons["assignments.add"].isHittable)
        capture(app, "Dense list")
    }

    func testAccessibilityTextSizeWithLongContent() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-design", "--large-type"]; app.launch()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["assignments.filter"].exists)
        capture(app, "Accessibility text size")
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "editor.title").firstMatch.waitForExistence(timeout: 5))
        capture(app, "Large editor")
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
