import XCTest
@testable import HomeworkDomain

final class PriorityTests: XCTestCase {
    func testUrgencyHasStableStorageValues() throws {
        XCTAssertEqual(Priority.allCases.map(\.rawValue), [1, 2, 3, 4])
        let data = try JSONEncoder().encode(Priority.urgent)
        XCTAssertEqual(try JSONDecoder().decode(Priority.self, from: data), .urgent)
        XCTAssertThrowsError(try JSONDecoder().decode(Priority.self, from: Data("5".utf8)))
    }
}
