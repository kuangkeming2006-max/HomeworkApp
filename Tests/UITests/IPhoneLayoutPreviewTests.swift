import XCTest

/// Focused runtime screenshots for the requested iPhone 15 Pro layout.
/// Historical regression tests remain separate.
@MainActor
final class IPhoneLayoutPreviewTests: HomeworkUITestCase {
    func testCaptureNativeNavigation() {
        continueAfterFailure = false
        let app = launch()
        let list = app.collectionViews["assignments.list"]
        XCTAssertTrue(list.waitForExistence(timeout: 20))
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 5), "Navigation must use the system tab bar")
        XCTAssertEqual(tabs.buttons.count, 4)
        let categories = app.segmentedControls["assignments.filter"]
        XCTAssertTrue(categories.waitForExistence(timeout: 5))
        let assignmentTitle = app.navigationBars["Assignments"].staticTexts["Assignments"]
        XCTAssertTrue(assignmentTitle.isHittable)
        let assignmentTitleY = assignmentTitle.frame.minY
        capture("Assignments — native glass and aligned title")
        recordFrames(app: app, tabs: tabs, categories: categories)

        for index in 1...2 {
            categories.buttons["Abandoned"].tap()
            XCTAssertTrue(categories.buttons["Abandoned"].isSelected)
            if index == 1 {
                let last = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.' AND label CONTAINS 'Optional reading'")).firstMatch
                XCTAssertTrue(last.isHittable)
                XCTAssertLessThanOrEqual(last.frame.maxY, tabs.frame.minY + 2, "The final row must scroll clear of the tab bar")
                capture("Abandoned — final row above native tabs")
            }
            categories.buttons["Upcoming"].tap()
            capture("Upcoming — return \(index)")
            XCTAssertTrue(categories.buttons["Upcoming"].isSelected, "A completed jump must not bounce back to Abandoned")
        }
        list.swipeDown()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        capture("Assignments — pull to reveal search")
        list.swipeUp()
        capture("Assignments — native compact heading")

        tabs.buttons["Calendar"].tap()
        let calendarTitle = app.navigationBars["Calendar"].staticTexts["Calendar"]
        XCTAssertTrue(calendarTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(calendarTitle.frame.minY, assignmentTitleY, accuracy: 2)
        XCTAssertTrue(app.buttons["calendar.add"].isHittable)
        capture("Calendar — native toolbar and bottom safe area")
        tabs.buttons["Briefing"].tap()
        XCTAssertTrue(app.navigationBars["Briefing"].waitForExistence(timeout: 5))
        capture("Briefing — native title and tabs")
        tabs.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        capture("Settings — native title and tabs")
    }

    func testCaptureNativeActions() {
        continueAfterFailure = false
        let app = launch()
        let list = app.collectionViews["assignments.list"]
        XCTAssertTrue(list.waitForExistence(timeout: 20))
        let status = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        status.tap()
        let complete = app.buttons["assignment.status.complete"]
        let abandon = app.buttons["assignment.status.abandon"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        XCTAssertTrue(abandon.exists)
        XCTAssertGreaterThan(abandon.frame.minY, complete.frame.maxY)
        XCTAssertFalse(app.buttons["assignment.status.cancel"].exists)
        capture("Status — native fixed-height sheet")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(complete.waitForNonExistence(timeout: 5), "Tapping the backdrop must close the sheet")
        status.tap()
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        let undo = app.buttons["assignments.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        capture("Undo — system tab-bar accessory")
        undo.tap()

        let first = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        first.tap()
        let form = app.descendants(matching: .any).matching(identifier: "editor.form").firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 5))
        for _ in 0..<4 {
            if app.buttons["attachments.files"].exists && app.buttons["attachments.files"].isHittable { break }
            form.swipeUp()
        }
        capture("Editor — attachments clear of native tabs")
        form.swipeUp()
        capture("Editor — final controls remain reachable")
        app.navigationBars["Assignment"].buttons.element(boundBy: 0).tap()
        app.segmentedControls["assignments.filter"].buttons["Completed"].tap()
        let completed = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.' AND label CONTAINS 'Finished problem set'")).firstMatch
        list.cells.containing(.button, identifier: completed.identifier).buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["assignment.status.delete"].waitForExistence(timeout: 5))
        capture("Status — native restore and red delete")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-design", "--fixture-assignments"]
        app.launch()
        return app
    }

    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    private func recordFrames(app: XCUIApplication, tabs: XCUIElement, categories: XCUIElement) {
        let widths = tabs.buttons.allElementsBoundByIndex.map { $0.frame.width }
        let text = "screen=\(app.frame)\ntabBar=\(tabs.frame)\nitemWidths=\(widths)\ncategories=\(categories.frame)"
        let attachment = XCTAttachment(string: text)
        attachment.name = "iPhone 15 Pro native layout frames"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
