import XCTest

/// A short runtime capture of the changed flow, not the broad regression suite.
@MainActor
final class InteractionPreviewTests: HomeworkUITestCase {
    func testCaptureUpdatedIPhoneInteractions() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--fixture-design"]
        app.launch()
        let list = app.collectionViews["assignments.list"]
        let thumbnail = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.thumbnail.'")).firstMatch
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["assignments.add"].isHittable)
        XCTAssertTrue(app.buttons["assignments.ai"].isHittable)
        let categories = app.segmentedControls["assignments.filter"]
        XCTAssertTrue(categories.waitForExistence(timeout: 5))
        XCTAssertEqual(categories.buttons.count, 3)
        XCTAssertTrue(categories.buttons["Upcoming"].exists)
        XCTAssertTrue(categories.buttons["Completed"].exists)
        XCTAssertTrue(categories.buttons["Abandoned"].exists)
        XCTAssertFalse(categories.buttons["All"].exists)
        capture("Three categories and colored sections")
        categories.buttons["Completed"].tap()
        list.swipeUp()
        XCTAssertTrue(app.staticTexts["assignments.compactTitle"].waitForExistence(timeout: 5))
        capture("Completed category and compact heading")
        categories.buttons["Upcoming"].tap()
        thumbnail.tap()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForExistence(timeout: 10))
        capture("Full screen image")
        app.swipeDown()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForNonExistence(timeout: 5))

        let status = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.complete.'")).firstMatch
        status.tap()
        let complete = app.buttons["assignment.status.complete"]
        let abandon = app.buttons["assignment.status.abandon"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        XCTAssertTrue(abandon.exists)
        XCTAssertFalse(app.buttons["assignment.status.cancel"].exists)
        XCTAssertFalse(app.buttons["Cancel"].exists)
        XCTAssertGreaterThan(abandon.frame.minY, complete.frame.maxY)
        capture("Fixed vertical status card")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(complete.waitForNonExistence(timeout: 5))
        status.tap()
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        XCTAssertTrue(app.buttons["assignments.undo"].waitForExistence(timeout: 5))
        capture("Undo countdown")
        app.buttons["assignments.undo"].tap()

        let firstRow = list.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        let cell = list.cells.containing(.button, identifier: firstRow.identifier).firstMatch
        cell.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: cell.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)))
        XCTAssertTrue(app.buttons["assignments.undo"].waitForExistence(timeout: 5))
        capture("Full swipe complete")
        app.buttons["assignments.undo"].tap()
        cell.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: cell.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)))
        XCTAssertTrue(app.buttons["assignments.undo"].waitForExistence(timeout: 5))
        capture("Full swipe delete")
        app.buttons["assignments.undo"].tap()

        app.buttons["navigation.calendar"].tap()
        let month = app.buttons["calendar.month"]
        XCTAssertTrue(month.waitForExistence(timeout: 5))
        let selected = app.staticTexts["calendar.selectedDate"]
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        let selectedBeforeBrowsing = selected.label
        let originalMonth = month.label
        let grid = app.otherElements["calendar.grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        let days = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calendar.day.'"))
        let dragStartDay = days.element(boundBy: 10)
        XCTAssertTrue(dragStartDay.exists)
        let forward = dragStartDay.frame.midX >= grid.frame.midX
        let endY = (dragStartDay.frame.midY - grid.frame.minY) / grid.frame.height
        dragStartDay.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: grid.coordinate(withNormalizedOffset: CGVector(dx: forward ? 0.05 : 0.95, dy: endY)))
        let dragged = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", originalMonth), object: month)
        XCTAssertEqual(XCTWaiter.wait(for: [dragged], timeout: 5), .completed)
        XCTAssertEqual(selected.label, selectedBeforeBrowsing, "A drag that starts on a date must browse without selecting it")
        capture("Calendar date-origin drag preserves selection")
        app.buttons[forward ? "calendar.previous" : "calendar.next"].tap()
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", originalMonth), object: month)
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 5), .completed)
        XCTAssertEqual(selected.label, selectedBeforeBrowsing)
        app.buttons["calendar.next"].tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", originalMonth), object: month)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        XCTAssertEqual(selected.label, selectedBeforeBrowsing, "Month arrows must preserve the selected date")
        capture("Calendar translated month")
        app.buttons["calendar.today"].tap()
        days.element(boundBy: Calendar.current.component(.day, from: Date()) == 1 ? 1 : 0).tap()
        let selectedByTap = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", selectedBeforeBrowsing), object: selected)
        XCTAssertEqual(XCTWaiter.wait(for: [selectedByTap], timeout: 5), .completed)
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
        XCTAssertTrue(app.buttons["settings.accent.purple"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'settings.accent.'")).count, 7)
        capture("Distinct theme color swatches")
        app.buttons["settings.accent.orange"].tap()
        capture("Selected orange theme")
        app.navigationBars["Theme color"].buttons.element(boundBy: 0).tap()
        app.buttons["navigation.assignments"].tap()
        capture("Assignments with restricted orange accent")
        firstRow.tap()
        let form = app.descendants(matching: .any).matching(identifier: "editor.form").firstMatch
        let image = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.preview.'")).firstMatch
        for _ in 0..<7 where !image.isHittable { form.swipeUp() }
        XCTAssertTrue(image.isHittable)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.remove.'")).firstMatch.exists)
        let photos = app.buttons["attachments.photos"]
        let files = app.buttons["attachments.files"]
        XCTAssertTrue(photos.exists); XCTAssertTrue(files.exists)
        XCTAssertEqual(photos.frame.midY, files.frame.midY, accuracy: 2)
        XCTAssertLessThan(photos.frame.midX, files.frame.midX)
        capture("Large editor image without filename")
        image.tap()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForExistence(timeout: 5))
        let share = app.buttons["attachment.image.share"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        XCTAssertTrue(share.isEnabled)
        share.tap()
        let closeShare = app.buttons.matching(NSPredicate(format: "label == 'Close'")).firstMatch
        XCTAssertTrue(closeShare.waitForExistence(timeout: 10))
        capture("Native image share sheet")
        closeShare.tap()
        XCTAssertTrue(closeShare.waitForNonExistence(timeout: 5))
        app.swipeDown()
        XCTAssertTrue(app.buttons["attachment.image.close"].waitForNonExistence(timeout: 5))
        let imageRow = app.cells.containing(.button, identifier: image.identifier).firstMatch
        imageRow.swipeLeft()
        let deleteAttachment = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.remove.'")).firstMatch
        XCTAssertTrue(deleteAttachment.waitForExistence(timeout: 5))
        capture("Red attachment swipe action")
        deleteAttachment.tap()
        let remove = app.buttons["Remove attachment"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        capture("Confirm attachment removal")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(remove.waitForNonExistence(timeout: 5))
        XCTAssertTrue(image.exists, "Canceling removal must keep the image")
    }

    private func capture(_ name: String) {
        let afterTransition = Date().addingTimeInterval(0.4)
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in Date() >= afterTransition }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 2), .completed)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
