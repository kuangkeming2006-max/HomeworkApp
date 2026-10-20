import XCTest
@testable import HomeworkApp

final class CompositionTests: XCTestCase {
    @MainActor
    func testAppContainerIsAvailableWithoutNetworkOrCredentials() {
        let container = AppContainer()
        XCTAssertEqual(container.version, "0.1.0")
        XCTAssertEqual(AppSection.allCases.map(\.rawValue), ["Assignments", "Calendar", "Settings"])
    }
}
