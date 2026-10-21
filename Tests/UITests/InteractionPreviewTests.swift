import XCTest

/// A short runtime capture of the changed flow, not the broad regression suite.
@MainActor
final class InteractionPreviewTests: HomeworkUITestCase {
    func testCaptureUpdatedIPhoneInteractions() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-design"]
        app.launch()
        let thumbnail = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.thumbnail.'")).firstMatch
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 20))
        capture("Assignments sections and equal tabs")
        thumbnail.tap()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForExistence(timeout: 10))
        capture("Full screen image")
        app.swipeDown()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForNonExistence(timeout: 5))

        let status = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        status.tap()
        XCTAssertTrue(app.buttons["assignment.status.complete"].waitForExistence(timeout: 5))
        capture("Three status actions")
        app.buttons["assignment.status.complete"].tap()
        XCTAssertTrue(app.buttons["assignments.undo"].waitForExistence(timeout: 5))
        capture("Undo countdown")
        app.buttons["assignments.undo"].tap()

        app.buttons["navigation.calendar"].tap()
        let month = app.buttons["calendar.month"]
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        let originalMonth = month.label
        app.buttons["calendar.next"].tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", originalMonth), object: month)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        capture("Calendar translated month")
        app.buttons["calendar.today"].tap()
        capture("Calendar selected day")

        app.buttons["navigation.settings"].tap()
        XCTAssertTrue(app.buttons["settings.appearance"].waitForExistence(timeout: 5))
        capture("Appearance settings")
        app.buttons["settings.appearance"].tap()
        app.buttons["Dark"].tap()
        capture("Dark appearance")
        app.buttons["settings.appearance"].tap()
        app.buttons["System"].tap()
        app.buttons["settings.accent"].tap()
        app.buttons["Purple"].tap()
        capture("Purple theme")
        app.buttons["navigation.assignments"].tap()
        capture("Assignments with purple theme")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
