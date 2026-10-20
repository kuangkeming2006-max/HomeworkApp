import XCTest

@MainActor
final class StatusFlowTests: HomeworkUITestCase {
    func testShortAndCancelledSwipesPreserveAssignments() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-assignments"]; app.launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        let cell = app.cells.containing(.button, identifier: rows.firstMatch.identifier).firstMatch
        XCTAssertTrue(cell.exists)
        let start = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertEqual(rows.count, 3)
        cell.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].exists)
        XCTAssertEqual(rows.count, 3, "A trailing full swipe must never delete automatically")
        cell.swipeRight()
        XCTAssertEqual(rows.count, 3)
    }
    func testAbandonUndoRestoreAndSearch() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-assignments"]; app.launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch.tap()
        app.buttons["Abandon"].tap()
        waitForRows(rows, count: 2)
        XCTAssertTrue(app.buttons["assignments.undo"].exists)
        capture(app, "Undo")
        app.buttons["assignments.undo"].tap(); waitForRows(rows, count: 3)
        rows.firstMatch.swipeLeft()
        XCTAssertTrue(app.buttons["Delete"].exists)
        capture(app, "Trailing swipe")
        app.buttons["Abandon"].tap()
        selectCategory("Abandoned", app: app)
        waitForRows(rows, count: 1)
        capture(app, "Abandoned")
        rows.firstMatch.swipeRight()
        XCTAssertTrue(app.buttons["Restore"].exists)
        app.buttons["Restore"].tap()
        waitForRows(rows, count: 0)
        selectCategory("Upcoming", app: app)
        app.swipeDown()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5)); search.tap(); search.typeText("Low earlier")
        waitForRows(rows, count: 1); XCTAssertTrue(rows.firstMatch.label.contains("Low earlier"))
        capture(app, "Search")
    }

    private func waitForRows(_ rows: XCUIElementQuery, count: Int) {
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in rows.count == count }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
        XCTAssertEqual(rows.count, count)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
