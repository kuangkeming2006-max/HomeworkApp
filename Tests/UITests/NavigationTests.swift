import XCTest

@MainActor
final class NavigationTests: HomeworkUITestCase {
    func testNavigationAndCaptureScreens() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        let environment = ProcessInfo.processInfo.environment
        let orientation = environment["TEST_ORIENTATION"] ?? "portrait"
        XCTAssertTrue(["portrait", "landscape"].contains(orientation),
                      "The scheme must expand TEST_ORIENTATION; received '\(orientation)'")
        XCUIDevice.shared.orientation = orientation == "landscape" ? .landscapeLeft : .portrait
        app.launch()
        XCTAssertTrue(app.staticTexts["No assignments yet"].waitForExistence(timeout: 15))
        capture("Assignments")

        navigate("Calendar", in: app)
        XCTAssertTrue(app.buttons["calendar.month"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["calendar.next"].exists)
        XCTAssertTrue(app.buttons["calendar.previous"].exists)
        XCTAssertTrue(app.staticTexts["No assignments this day"].exists)
        let month = app.buttons["calendar.month"].label
        app.buttons["calendar.next"].tap()
        XCTAssertNotEqual(app.buttons["calendar.month"].label, month)
        app.buttons["calendar.previous"].tap()
        XCTAssertEqual(app.buttons["calendar.month"].label, month)
        app.buttons["calendar.month"].tap()
        XCTAssertTrue(app.buttons["calendar.yearPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["calendar.monthPicker"].exists)
        capture("Month and year")
        app.buttons["calendar.go"].tap()
        XCTAssertEqual(app.buttons["calendar.month"].label, month)
        capture("Calendar")

        navigate("Settings", in: app)
        let storage = app.staticTexts["settings.storage"]
        for _ in 0..<4 where !storage.exists { app.swipeUp() }
        XCTAssertTrue(storage.waitForExistence(timeout: 5))
        XCTAssertEqual(storage.label, "Storage, On this device")
        capture("Settings")

        navigate("Assignments", in: app)
        XCTAssertTrue(app.staticTexts["No assignments yet"].waitForExistence(timeout: 5))
    }

    private func navigate(_ title: String, in app: XCUIApplication) {
        let tab = app.tabBars.buttons[title]
        if tab.exists { tab.tap(); return }
        let sidebar = app.staticTexts[title].firstMatch
        if !sidebar.exists {
            let showSidebar = app.buttons["Show Sidebar"].firstMatch
            if showSidebar.exists { showSidebar.tap() }
        }
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
        sidebar.tap()
    }

    private func capture(_ page: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = page
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
