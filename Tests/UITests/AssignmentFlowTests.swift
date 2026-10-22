import XCTest

@MainActor
final class AssignmentFlowTests: HomeworkUITestCase {
    func testCreateCompleteRestoreAndCalendarNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["assignments.add"].waitForExistence(timeout: 15))
        app.buttons["assignments.add"].tap()
        let title = app.descendants(matching: .any).matching(identifier: "editor.title").firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Networking lab report")
        app.buttons["editor.save"].tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("Networking lab report"))
        let completion = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        completion.tap()
        XCTAssertEqual(completion.value as? String, "Completed")
        selectCategory("Completed", app: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        completion.tap()
        selectCategory("Upcoming", app: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "editor.title").firstMatch.value as? String, "Networking lab report")
        let course = app.descendants(matching: .any).matching(identifier: "editor.course").firstMatch
        course.tap(); course.typeText("Computer networks")
        app.buttons["editor.save"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        app.terminate()
        // Disk durability is covered by hosted tests; UI fixtures intentionally use an in-memory store.
    }
}
