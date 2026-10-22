import XCTest

/// Focused coverage and real simulator evidence for PR #1's native redesign.
@MainActor
final class IPhoneLayoutPreviewTests: HomeworkUITestCase {
    func testAnchoredMenusFilteringAndRepeatedToolbars() {
        continueAfterFailure = false
        let app = launch()
        let tabs = app.tabBars.firstMatch
        let titleY = app.navigationBars["Assignments"].staticTexts["Assignments"].frame.minY
        XCTAssertEqual(tabs.buttons.count, 4)
        XCTAssertFalse(app.segmentedControls["assignments.filter"].exists)
        app.buttons["assignments.sort"].tap()
        XCTAssertTrue(app.buttons["Deadline"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.sheets.firstMatch.exists)
        capture("Sort — anchored native Picker menu")
        app.buttons["Deadline"].tap()
        XCTAssertTrue(openRows(app).firstMatch.label.contains("Earlier lab report"))
        app.buttons["assignments.filter"].press(forDuration: 0.8)
        XCTAssertTrue(app.buttons["All"].waitForExistence(timeout: 5))
        capture("Categories — native long-press selection")
        let allFrame = app.buttons["All"].frame
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.85)).tap()
        let allPosition = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: allFrame.midX, dy: allFrame.midY))
        app.buttons["assignments.filter"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.8, thenDragTo: allPosition)
        XCTAssertEqual(app.buttons["assignments.filter"].value as? String, "All")
        XCTAssertTrue(app.descendants(matching: .any)["assignments.section.active"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["assignments.section.completed"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["assignments.section.abandoned"].exists)
        capture("All — continuous colored status sections")
        let last = openRows(app).matching(NSPredicate(format: "label CONTAINS 'Optional reading'")).firstMatch
        app.collectionViews["assignments.list"].swipeUp()
        XCTAssertTrue(last.isHittable)
        XCTAssertLessThanOrEqual(last.frame.maxY, tabs.frame.minY + 2, "The final assignment must scroll above the native tab bar")
        capture("All — final row clear of native tabs")
        category("Completed", app)
        XCTAssertTrue(openRows(app).firstMatch.label.contains("Finished problem set"))
        XCTAssertEqual(openRows(app).count, 1)
        category("Abandoned", app)
        XCTAssertTrue(openRows(app).firstMatch.label.contains("Optional reading"))
        category("Deleted", app)
        XCTAssertTrue(app.descendants(matching: .any)["assignments.empty"].exists)
        category("Upcoming", app)
        XCTAssertEqual(openRows(app).count, 2)
        let title = app.navigationBars["Assignments"].staticTexts["Assignments"]
        XCTAssertTrue(title.isHittable)
        capture("Upcoming — native title and borderless category")
        for _ in 0..<2 {
            tabs.buttons["Calendar"].tap()
            XCTAssertTrue(app.buttons["calendar.today"].isHittable)
            XCTAssertTrue(app.buttons["calendar.add"].isHittable)
            XCTAssertEqual(app.navigationBars["Calendar"].staticTexts["Calendar"].frame.minY, titleY, accuracy: 2)
            tabs.buttons["Assignments"].tap()
            XCTAssertTrue(app.buttons["assignments.sort"].isHittable)
            XCTAssertTrue(app.buttons["assignments.ai"].isHittable)
            XCTAssertEqual(app.buttons["assignments.filter"].value as? String, "Upcoming")
            tabs.buttons["Briefing"].tap()
            tabs.buttons["Calendar"].tap()
            XCTAssertTrue(app.buttons["calendar.add"].isHittable)
            tabs.buttons["Settings"].tap()
            tabs.buttons["Assignments"].tap()
            XCTAssertTrue(app.buttons["assignments.add"].isHittable)
        }
        capture("Toolbar — repeated page returns")
        app.collectionViews["assignments.list"].swipeDown()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        capture("Search — pull to reveal")
    }

    func testImmediateCompletionDelayedRemovalUndoAndTabExit() {
        continueAfterFailure = false
        let app = launch()
        let button = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        let identifier = button.identifier
        button.tap()
        XCTAssertEqual(app.buttons[identifier].value as? String, "Completed")
        XCTAssertFalse(app.sheets.firstMatch.exists)
        XCTAssertTrue(app.buttons["assignments.undo"].exists)
        capture("Completion — immediate checkmark and native Undo")
        app.buttons["assignments.undo"].tap()
        XCTAssertEqual(app.buttons[identifier].value as? String, "Active")
        app.buttons[identifier].tap()
        app.buttons[identifier].tap()
        XCTAssertEqual(app.buttons[identifier].value as? String, "Active")
        app.buttons[identifier].tap()
        XCTAssertTrue(app.buttons[identifier].exists)
        XCTAssertTrue(app.buttons[identifier].waitForNonExistence(timeout: 7))
        capture("Upcoming — row removed after five seconds")
        category("Completed", app)
        app.buttons[identifier].tap()
        category("Upcoming", app)
        app.buttons[identifier].tap()
        app.tabBars.buttons["Calendar"].tap()
        app.tabBars.buttons["Assignments"].tap()
        XCTAssertFalse(app.buttons[identifier].exists, "Leaving the tab clears pending Upcoming visibility")
        category("All", app)
        let rowsBefore = openRows(app).count
        let remaining = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.' AND value == 'Active'")).firstMatch
        let remainingID = remaining.identifier
        remaining.tap()
        XCTAssertEqual(app.buttons[remainingID].value as? String, "Completed")
        XCTAssertEqual(openRows(app).count, rowsBefore)
        capture("All — completed item retains identity")
    }

    func testExplicitSaveBackAlertAndInteractiveBackGuard() {
        continueAfterFailure = false
        let app = launch()
        let row = openRows(app).firstMatch
        let rowID = row.identifier, original = row.label
        row.tap()
        XCTAssertTrue(app.buttons["editor.save"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable)
        let title = app.textFields["editor.title"].exists ? app.textFields["editor.title"] : app.textViews["editor.title"]
        title.tap(); title.typeText(" revised")
        app.navigationBars["Assignment"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.alerts["Save changes?"].waitForExistence(timeout: 5))
        capture("Editor — centered Save Discard Keep Editing alert")
        app.alerts.buttons["Keep Editing"].tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.45))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.45)))
        XCTAssertTrue(app.alerts["Save changes?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Discard Changes"].tap()
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons[rowID].label, original)
        app.buttons[rowID].tap()
        let editedTitle = app.textFields["editor.title"].exists ? app.textFields["editor.title"] : app.textViews["editor.title"]
        editedTitle.tap(); editedTitle.typeText(" saved")
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[rowID].label.contains("saved"))
        app.buttons["assignments.add"].tap()
        let newTitle = app.textFields["editor.title"].exists ? app.textFields["editor.title"] : app.textViews["editor.title"]
        XCTAssertTrue(newTitle.waitForExistence(timeout: 5))
        newTitle.tap(); newTitle.typeText("Explicitly saved new assignment")
        app.buttons["editor.back"].tap()
        XCTAssertTrue(app.alerts["Save changes?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Keep Editing"].tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)))
        XCTAssertTrue(app.alerts["Save changes?"].waitForExistence(timeout: 5), "A dirty sheet must report attempted interactive dismissal")
        capture("New draft — interactive dismissal asks before saving")
        app.alerts.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["assignments.add"].waitForExistence(timeout: 5))
        XCTAssertTrue(openRows(app).matching(NSPredicate(format: "label CONTAINS 'Explicitly saved new assignment'")).firstMatch.exists)
        capture("Editor — explicit Save returns to the list")
    }

    func testImagesStagedRemovalAndCompactImportRow() {
        continueAfterFailure = false
        let app = launch()
        let thumbnails = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.thumbnail.'"))
        XCTAssertTrue(thumbnails.firstMatch.waitForExistence(timeout: 10))
        thumbnails.firstMatch.tap()
        let image = app.images["attachment.image.content"]
        XCTAssertTrue(image.waitForExistence(timeout: 10))
        image.doubleTap()
        image.swipeDown()
        XCTAssertTrue(app.buttons["attachment.image.close"].exists, "Zoomed panning must not dismiss")
        image.pinch(withScale: 1.3, velocity: 1)
        capture("Image — zoomed downward pan remains open")
        image.doubleTap()
        image.swipeDown()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForNonExistence(timeout: 5))
        thumbnails.firstMatch.tap()
        XCTAssertTrue(app.buttons["attachment.image.share"].waitForExistence(timeout: 5))
        app.buttons["attachment.image.close"].tap()
        openRows(app).firstMatch.tap()
        let form = app.descendants(matching: .any)["editor.form"]
        let files = app.buttons["attachments.files"]
        for _ in 0..<6 where !files.isHittable { form.swipeUp() }
        XCTAssertTrue(files.isHittable)
        XCTAssertLessThanOrEqual(files.frame.height, 48)
        XCTAssertTrue(app.buttons["attachments.photos"].isHittable)
        XCTAssertEqual(files.frame.minY, app.buttons["attachments.photos"].frame.minY, accuracy: 2)
        capture("Editor — compact native attachment import row")
        let preview = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.preview.'")).firstMatch
        preview.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Remove attachment"].waitForExistence(timeout: 5))
        app.buttons["Remove attachment"].tap()
        app.navigationBars["Assignment"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.alerts["Save changes?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Discard Changes"].tap()
        XCTAssertEqual(thumbnails.count, 2, "Discard must preserve the original attachments")
        capture("Attachments — discarded removal preserves originals")
        openRows(app).firstMatch.press(forDuration: 0.8)
        app.buttons["Delete"].tap()
        category("Deleted", app)
        XCTAssertEqual(thumbnails.count, 2)
        thumbnails.firstMatch.tap()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForExistence(timeout: 5))
        app.buttons["attachment.image.close"].tap()
        capture("Deleted — recoverable assignment and original attachments")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.recover.'")).firstMatch.tap()
        category("Upcoming", app)
        XCTAssertEqual(thumbnails.count, 2)
    }

    func testCalendarSwipesButtonsDatesAndHighlight() {
        continueAfterFailure = false
        let app = launch()
        app.tabBars.buttons["Calendar"].tap()
        let selected = app.staticTexts["calendar.selectedDate"]
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        let date = selected.label
        let grid = app.descendants(matching: .any)["calendar.grid"]
        grid.swipeLeft()
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        XCTAssertEqual(selected.label, date)
        XCTAssertEqual(selectedDays(app).count, 0, "A browsed month must not show the old date's highlight")
        capture("Calendar — browsed month without stale highlight")
        app.buttons["calendar.previous"].tap()
        app.buttons["calendar.next"].tap()
        app.buttons["calendar.previous"].tap()
        app.buttons["calendar.today"].tap()
        XCTAssertEqual(selected.label, date)
        XCTAssertEqual(selectedDays(app).count, 1)
        let days = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calendar.day.'"))
        days.element(boundBy: 0).tap()
        XCTAssertNotEqual(selected.label, date)
        XCTAssertEqual(selectedDays(app).count, 1)
        capture("Calendar — selected date and overlapping details")
        app.buttons["calendar.month"].tap()
        XCTAssertTrue(app.buttons["calendar.go"].waitForExistence(timeout: 5))
        app.buttons["calendar.go"].tap()
        app.buttons["calendar.today"].tap()
        XCTAssertEqual(selectedDays(app).count, 1)
        capture("Calendar — Today restores one correct highlight")
    }

    func testSecondaryPagesAndDarkReducedMotionAccessibility() {
        continueAfterFailure = false
        let app = launch(["--dark", "--reduce-motion", "--large-type"])
        capture("Accessibility — dark mode and large text Upcoming")
        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings.accent"].tap()
        XCTAssertTrue(app.navigationBars["Theme color"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable)
        capture("Theme — dark colors and hidden secondary tab bar")
        app.navigationBars["Theme color"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.tabBars.buttons["Calendar"].isHittable)
        app.buttons["settings.ai"].tap()
        XCTAssertTrue(app.navigationBars["AI provider"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable)
        capture("AI settings — secondary native navigation")
        app.navigationBars["AI provider"].buttons.element(boundBy: 0).tap()
        let backup = app.buttons["settings.backup"]
        let settings = app.descendants(matching: .any)["settings.form"]
        for _ in 0..<4 where !backup.isHittable { settings.swipeUp() }
        backup.tap()
        XCTAssertTrue(app.navigationBars["Backup and restore"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable)
        capture("Backup — native secondary page without tabs")
        app.navigationBars["Backup and restore"].buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Calendar"].tap()
        app.buttons["calendar.next"].tap()
        app.buttons["calendar.today"].tap()
        XCTAssertEqual(selectedDays(app).count, 1)
        capture("Calendar — dark Reduce Motion and accessibility text")
        let details = app.staticTexts["calendar.selectedDate"]
        let date = details.label
        let originalY = details.frame.minY
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.57))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)))
        XCTAssertLessThan(details.frame.minY, originalY - 20, "A vertical drag starting inside the grid must scroll the page")
        XCTAssertEqual(details.label, date, "Vertical scrolling must not select a date")
        XCTAssertTrue(details.isHittable)
        XCTAssertLessThanOrEqual(details.frame.maxY, app.tabBars.firstMatch.frame.minY + 2)
        capture("Calendar — accessible details scrolled clear of tabs")
    }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-design"] + extra
        app.launch()
        XCTAssertTrue(app.collectionViews["assignments.list"].waitForExistence(timeout: 20))
        XCTAssertTrue(openRows(app).firstMatch.waitForExistence(timeout: 20))
        return app
    }
    private func category(_ name: String, _ app: XCUIApplication) {
        app.buttons["assignments.filter"].tap()
        XCTAssertTrue(app.buttons[name].waitForExistence(timeout: 5))
        app.buttons[name].tap()
        XCTAssertEqual(app.buttons["assignments.filter"].value as? String, name)
    }
    private func openRows(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'"))
    }
    private func selectedDays(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calendar.day.' AND selected == true"))
    }
    private func capture(_ name: String) {
        // Capture the resting native presentation; production transitions have no delay.
        let settledAt = Date().addingTimeInterval(0.45)
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in Date() >= settledAt }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 2), .completed)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }
}
