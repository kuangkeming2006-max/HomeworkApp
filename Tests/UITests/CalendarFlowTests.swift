import XCTest

@MainActor
final class CalendarFlowTests: HomeworkUITestCase {
    func testDirectMonthYearSelectionLeapDayAndToday() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-assignments"]; app.launch()
        if app.tabBars.buttons["Calendar"].exists { app.tabBars.buttons["Calendar"].tap() }
        else {
            if !app.staticTexts["Calendar"].firstMatch.exists { app.buttons["Show Sidebar"].tap() }
            app.staticTexts["Calendar"].firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["calendar.month"].waitForExistence(timeout: 5))
        app.buttons["calendar.month"].tap()
        app.buttons["calendar.yearPicker"].tap(); app.buttons["2028"].tap()
        app.buttons["calendar.monthPicker"].tap(); app.buttons["February"].tap()
        capture(app, "Calendar selectors")
        app.buttons["calendar.go"].tap()
        let leap = app.buttons["calendar.day.2028-02-29"]
        XCTAssertTrue(leap.waitForExistence(timeout: 5)); leap.tap()
        XCTAssertTrue(app.staticTexts["calendar.selectedDate"].label.contains("29"))
        capture(app, "Leap day")
        app.buttons["calendar.next"].tap()
        XCTAssertTrue(app.buttons["calendar.month"].label.contains("March"))
        app.buttons["calendar.previous"].tap()
        XCTAssertTrue(app.buttons["calendar.month"].label.contains("February"))
        app.buttons["calendar.today"].tap()
        let year = Calendar.current.component(.year, from: Date())
        XCTAssertTrue(app.buttons["calendar.month"].label.contains(String(year)))
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
