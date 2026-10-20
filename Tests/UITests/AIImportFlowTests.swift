import XCTest

@MainActor
final class AIImportFlowTests: HomeworkUITestCase {
    func testAIPreviewRequiresConfirmationAndCanSaveSelectedCandidates() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-ai"]
        app.launch()
        XCTAssertTrue(app.buttons["assignments.ai"].waitForExistence(timeout: 15))
        app.buttons["assignments.ai"].tap()
        let input = app.textViews["ai.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("Submit the networking lab this Friday.")
        capture("AI input")
        app.buttons["ai.analyze"].tap()
        XCTAssertTrue(app.textFields["ai.title.0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["ai.title.0"].value as? String, "AI networking lab")
        let save = app.navigationBars.buttons["ai.confirm"]
        XCTAssertFalse(save.isEnabled)
        capture("AI confirmation required")
        let second = app.switches["ai.select.1"]
        for _ in 0..<5 {
            if second.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(second.isHittable)
        second.tap()
        XCTAssertEqual(second.value as? String, "0")
        // A cold simulator accessibility snapshot can take over four seconds.
        // Use the native state wait so there is time to observe the updated button.
        XCTAssertTrue(save.wait(for: \.isEnabled, toEqual: true, timeout: 15))
        save.tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("AI networking lab"))
        capture("AI imported assignment")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
