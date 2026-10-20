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
        app.buttons["ai.analyze"].tap()
        XCTAssertTrue(app.textFields["ai.title.0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["ai.title.0"].value as? String, "AI networking lab")
        XCTAssertFalse(app.buttons["ai.confirm"].isEnabled)
        let second = app.switches["ai.select.1"]
        for _ in 0..<5 where !second.isHittable { app.swipeUp() }
        XCTAssertTrue(second.isHittable)
        second.tap()
        XCTAssertEqual(second.value as? String, "0")
        let save = app.buttons["ai.confirm"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
        app.buttons["ai.confirm"].tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'assignment.open.'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("AI networking lab"))
    }
}
