import XCTest

@MainActor
final class FeatureFlowTests: HomeworkUITestCase {
    func testPriorityAndDeadlineSortingAndDeletion() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-assignments"]
        app.launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(rows.count, 3)
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("Urgent later"))
        XCTAssertTrue(rows.element(boundBy: 2).label.contains("Low earlier"))
        app.buttons["assignments.sort"].tap()
        app.buttons["Deadline"].tap()
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("Low earlier"))
        XCTAssertTrue(rows.element(boundBy: 2).label.contains("Urgent later"))
        rows.element(boundBy: 0).press(forDuration: 1)
        app.buttons["Delete"].tap()
        XCTAssertEqual(rows.count, 2)
        XCTAssertFalse(rows.allElementsBoundByIndex.contains { $0.label.contains("Low earlier") })
        app.segmentedControls.buttons["All"].tap()
        XCTAssertEqual(rows.count, 2, "Deleted assignments must also be hidden from All")
    }

    func testReminderAndAttachmentControlsOnExistingAssignment() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-assignments"]
        app.launch()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15)); row.tap()
        let reminder = app.buttons["reminder.preset"]
        for _ in 0..<5 where !reminder.isHittable { app.swipeUp() }
        XCTAssertTrue(reminder.isHittable); reminder.tap()
        app.buttons["3 hours before"].tap()
        XCTAssertTrue(reminder.label.contains("3 hours before"))
        let files = app.buttons["attachments.files"]
        for _ in 0..<4 where !files.isHittable { app.swipeUp() }
        XCTAssertTrue(files.isHittable)
        XCTAssertTrue(app.buttons["attachments.photos"].exists)
        // File copying, persistence, removal and traversal rejection use real files in hosted tests.
    }

    func testProviderAndBackupSettingsAreReachable() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        navigateToSettings(app)
        app.buttons["settings.ai"].tap()
        XCTAssertTrue(app.textFields["provider.url"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["provider.model"].exists)
        XCTAssertTrue(app.secureTextFields["provider.key"].exists)
        app.terminate(); app.launch(); navigateToSettings(app)
        app.buttons["settings.backup"].tap()
        XCTAssertTrue(app.buttons["backup.export"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["backup.import"].exists)
    }

    private func navigateToSettings(_ app: XCUIApplication) {
        let tab = app.tabBars.buttons["Settings"]
        if tab.waitForExistence(timeout: 2) { tab.tap(); return }
        let sidebar = app.staticTexts["Settings"].firstMatch
        if !sidebar.exists, app.buttons["Show Sidebar"].exists { app.buttons["Show Sidebar"].tap() }
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5)); sidebar.tap()
    }
}
