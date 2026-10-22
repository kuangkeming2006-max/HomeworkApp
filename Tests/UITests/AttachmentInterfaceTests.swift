import XCTest

@MainActor
final class AttachmentInterfaceTests: HomeworkUITestCase {
    func testLongContentThumbnailsDocumentPickerAndPreview() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-design"]; app.launch()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'"))
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 15))
        capture(app, "Assignment thumbnails")
        rows.firstMatch.tap()
        let form = app.descendants(matching: .any).matching(identifier: "editor.form").firstMatch
        let files = app.buttons["attachments.files"]
        for _ in 0..<7 where !files.isHittable { form.swipeUp() }
        XCTAssertTrue(files.isHittable)
        capture(app, "Editor attachments")
        files.tap()
        // The document service loads in a separate process. Its iPad navigation bar has
        // a controller identifier rather than the visible Recents/Browse title.
        let browser = app.collectionViews["File View"]
        XCTAssertTrue(browser.waitForExistence(timeout: 30), "Files must open the native document browser")
        capture(app, "Native document browser")
        let dismiss = app.buttons.matching(NSPredicate(format: "label == 'Cancel' OR label == 'Close'")).firstMatch
        XCTAssertTrue(dismiss.waitForExistence(timeout: 15))
        dismiss.tap()
        XCTAssertTrue(browser.waitForNonExistence(timeout: 5))
        let previews = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'attachment.preview.'"))
        XCTAssertTrue(previews.firstMatch.waitForExistence(timeout: 5))
        previews.element(boundBy: 1).tap()
        let closePreview = app.buttons["QLOverlayDoneButtonAccessibilityIdentifier"]
        XCTAssertTrue(closePreview.waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["QLPDFViewControllerViewAccessibilityIdentifier"].waitForExistence(timeout: 30),
                      "The PDF must render in Quick Look")
        capture(app, "PDF preview")
        closePreview.tap()
        app.navigationBars["Assignment"].buttons.element(boundBy: 0).tap()
        let calendarTab = app.tabBars.buttons["Calendar"]
        if calendarTab.waitForExistence(timeout: 5) { calendarTab.tap() }
        else {
            if !app.staticTexts["Calendar"].firstMatch.exists { app.buttons["Show Sidebar"].tap() }
            app.staticTexts["Calendar"].firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["calendar.today"].waitForExistence(timeout: 5)); app.buttons["calendar.today"].tap()
        capture(app, "Calendar status aggregation")
    }

    func testNewAssignmentCanOpenPhotosAndFilesBeforeCreation() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["assignments.add"].tap()
        let form = app.descendants(matching: .any).matching(identifier: "editor.form").firstMatch
        let photos = app.buttons["attachments.photos"]
        for _ in 0..<7 where !photos.isHittable { form.swipeUp() }
        XCTAssertTrue(photos.isHittable); XCTAssertTrue(app.buttons["attachments.files"].exists)
        photos.tap()
        // The editor also has a Cancel button behind the system picker. Target the
        // picker's navigation bar, otherwise XCTest tries to scroll to a hidden button.
        let pickerCancel = app.navigationBars.matching(NSPredicate(format: "identifier != 'New assignment'"))
            .buttons["Cancel"].firstMatch
        XCTAssertTrue(pickerCancel.waitForExistence(timeout: 15))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: pickerCancel)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
        capture(app, "Native photo picker", includeTree: false)
        pickerCancel.tap()
        let editorCancel = app.buttons["editor.back"]
        XCTAssertTrue(editorCancel.waitForExistence(timeout: 5))
        let files = app.buttons["attachments.files"]
        XCTAssertTrue(files.waitForExistence(timeout: 5))
        for _ in 0..<2 where !files.isHittable { form.swipeUp() }
        XCTAssertTrue(files.isHittable, "Canceling Photos must return to the editable draft")
        editorCancel.tap()
        XCTAssertTrue(app.buttons["assignments.add"].waitForExistence(timeout: 5))
    }

    private func capture(_ app: XCUIApplication, _ name: String, includeTree: Bool = true) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        // Snapshotting a cold remote Photos service can stall its initialization. Other
        // captures and the failure handler retain full accessibility diagnostics.
        if includeTree {
            let tree = XCTAttachment(string: app.debugDescription); tree.name = name + " accessibility"; tree.lifetime = .keepAlways; add(tree)
        }
    }
}
