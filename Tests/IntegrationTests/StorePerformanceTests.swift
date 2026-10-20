import Foundation
import XCTest
import HomeworkDomain
@testable import HomeworkApp

@MainActor
private final class CountingRepository: AssignmentRepository {
    var fetches = 0
    var values: [Assignment] = []
    func fetchAll() throws -> [Assignment] { fetches += 1; return values }
    func save(_ assignments: [Assignment]) throws {
        let changes = Dictionary(uniqueKeysWithValues: assignments.map { ($0.id, $0) })
        values = values.map { changes[$0.id] ?? $0 }
    }
}

@MainActor
final class StorePerformanceTests: XCTestCase {
    func testSingleRecordMutationsNeverReloadTheEntireRepository() throws {
        let repository = CountingRepository()
        repository.values = (0..<1000).map { Assignment(title: "Synthetic \($0)", dueDate: Date()) }
        let store = try AssignmentStore(repository: repository)
        let id = try XCTUnwrap(store.assignments.first?.id)
        let clock = ContinuousClock()
        let duration = try clock.measure {
            for index in 0..<100 { try store.update(id) { $0.notes = "Edit \(index)" } }
        }
        XCTAssertEqual(repository.fetches, 1, "Only initial loading may fetch all records")
        XCTAssertEqual(store.assignment(id)?.notes, "Edit 99")
        XCTAssertEqual(store.assignment(id)?.localRevision, 101)
        XCTAssertThrowsError(try store.save([store.assignments[0], store.assignments[0]]))
        print("PERFORMANCE store: 100 changes / 1000 synthetic tasks = \(duration); previous reload strategy 101 fetches, current measured \(repository.fetches)")
    }
}
