import Foundation
import Observation
import HomeworkDomain

/// The only composition root. Platform services will be injected here in later phases.
@Observable @MainActor
final class AppContainer {
    let version = "0.1.0"
    private(set) var store: AssignmentStore?
    private(set) var startupError: String?
    let syncService: any SyncService = OfflineSyncService()

    init() { openStore() }

    func openStore() {
        do {
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            let database = try SwiftDataAssignmentRepository.makeContainer(inMemory: testing)
            let repository = SwiftDataAssignmentRepository(container: database)
            store = try AssignmentStore(repository: repository)
            startupError = nil
        } catch {
            startupError = "Your data could not be opened. It has not been erased. \(error.localizedDescription)"
        }
    }
}
