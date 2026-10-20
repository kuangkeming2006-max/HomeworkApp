import XCTest

@MainActor
final class BriefingFlowTests: HomeworkUITestCase {
    func testSharedLiveActivityLayouts() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--preview-activities"]; app.launch()
        navigate("Settings", app: app)
        let form = app.descendants(matching: .any).matching(identifier: "settings.form").firstMatch
        let preview = app.buttons["settings.activityLayouts"]
        for _ in 0..<8 where !preview.isHittable { form.swipeUp() }
        XCTAssertTrue(preview.isHittable); preview.tap()
        XCTAssertTrue(app.staticTexts["Lock Screen"].waitForExistence(timeout: 5))
        capture(app, "Live Activity shared layouts")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Expanded content"].exists)
        capture(app, "Live Activity expanded content")
    }
    func testPermissionExplanationCanBeSkippedWithoutBlockingTasks() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--show-onboarding"]; app.launch()
        XCTAssertTrue(app.buttons["onboarding.enable"].waitForExistence(timeout: 10))
        capture(app, "Notification explanation")
        app.buttons["onboarding.skip"].tap()
        XCTAssertTrue(app.buttons["assignments.add"].waitForExistence(timeout: 5))
    }
    func testBriefingAndNotificationPreferences() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--fixture-assignments"]; app.launch()
        navigate("Briefing", app: app)
        XCTAssertTrue(app.otherElements["briefing.progress"].waitForExistence(timeout: 5) || app.staticTexts["briefing.progress"].exists)
        XCTAssertTrue(app.buttons["briefing.next"].exists)
        capture(app, "Briefing")
        navigate("Settings", app: app)
        let live = app.switches["settings.liveActivities"]
        for _ in 0..<6 where !live.isHittable { app.swipeUp() }
        XCTAssertTrue(live.isHittable)
        let reports = app.switches["briefing.enabled"]
        for _ in 0..<3 where !reports.isHittable { app.swipeUp() }
        XCTAssertTrue(reports.isHittable)
        if (reports.value as? String) == "0" { reports.tap() }
        XCTAssertTrue(app.buttons["briefing.frequency"].waitForExistence(timeout: 5))
        capture(app, "Reminder preferences")
    }

    private func navigate(_ title: String, app: XCUIApplication) {
        if app.tabBars.buttons[title].exists { app.tabBars.buttons[title].tap(); return }
        if !app.staticTexts[title].firstMatch.exists, app.buttons["Show Sidebar"].exists { app.buttons["Show Sidebar"].tap() }
        XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 5)); app.staticTexts[title].firstMatch.tap()
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
