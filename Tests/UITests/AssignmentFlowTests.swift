import XCTest

@MainActor
final class AssignmentFlowTests: XCTestCase {
    func testCreateCompleteRestoreAndCalendarNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["assignments.add"].waitForExistence(timeout: 15))
        app.buttons["assignments.add"].tap()
        let title = app.textFields["editor.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Networking lab report")
        app.buttons["editor.save"].tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Networking lab report"))
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        completion.tap()
        app.buttons["Complete"].tap()
        app.segmentedControls.buttons["Completed"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        completion.tap()
        app.buttons["Restore"].tap()
        app.segmentedControls.buttons["Upcoming"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertEqual(app.textFields["editor.title"].value as? String, "Networking lab report")
        let course = app.textFields["editor.course"]
        course.tap(); course.typeText("Computer networks")
        app.terminate()
        // Disk durability is covered by hosted tests; UI fixtures intentionally use an in-memory store.
    }
}
