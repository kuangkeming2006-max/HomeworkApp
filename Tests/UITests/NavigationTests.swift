import XCTest

@MainActor
final class NavigationTests: XCTestCase {
    func testNavigationAndCaptureScreens() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        let environment = ProcessInfo.processInfo.environment
        let orientation = environment["TEST_ORIENTATION"] ?? "portrait"
        XCUIDevice.shared.orientation = orientation == "landscape" ? .landscapeLeft : .portrait
        app.launch()
        XCTAssertTrue(app.staticTexts["No assignments yet"].waitForExistence(timeout: 15))
        capture("Assignments")

        navigate("Calendar", in: app)
        XCTAssertTrue(app.staticTexts["Your deadlines, together"].waitForExistence(timeout: 5))
        capture("Calendar")

        navigate("Settings", in: app)
        let storage = app.staticTexts["settings.storage"]
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
