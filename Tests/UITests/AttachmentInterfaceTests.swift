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
        XCTAssertTrue(app.buttons["Done"].firstMatch.waitForExistence(timeout: 5))
        capture(app, "PDF preview")
        app.buttons["Done"].firstMatch.tap()
        if app.tabBars.buttons["Calendar"].exists { app.tabBars.buttons["Calendar"].tap() }
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
        XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout: 5))
        capture(app, "Native photo picker")
        app.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.buttons["attachments.files"].waitForExistence(timeout: 5))
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        let tree = XCTAttachment(string: app.debugDescription); tree.name = name + " accessibility"; tree.lifetime = .keepAlways; add(tree)
    }
}
