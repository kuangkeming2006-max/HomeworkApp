import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
final class AIImportTests: XCTestCase {
    func testPreviewDoesNotSaveAndConfirmationIsRequired() async throws {
        let repository = SwiftDataAssignmentRepository(container: try SwiftDataAssignmentRepository.makeContainer(inMemory: true))
        let store = try AssignmentStore(repository: repository)
        let model = AIImportViewModel(store: store, providerFactory: { FixtureLLMProvider() })
        model.candidates = try await FixtureLLMProvider().extract(LLMInput(text: "fixture"), context: ImportContext())
        XCTAssertTrue(try repository.fetchAll().isEmpty)
        XCTAssertFalse(model.canConfirm)
        XCTAssertFalse(model.confirm())
        XCTAssertTrue(try repository.fetchAll().isEmpty)
        model.candidates[1].selected = false
        XCTAssertTrue(model.canConfirm)
        XCTAssertTrue(model.confirm())
        XCTAssertEqual(try repository.fetchAll().map(\.title), ["AI networking lab"])
    }
}
