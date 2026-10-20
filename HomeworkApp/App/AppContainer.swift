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
    let preferences = AppPreferences()
    let notifications = NotificationCoordinator(client: LocalNotificationClient())
    private(set) var attachmentService: (any AttachmentService)?

    init() { openStore() }

    func openStore() {
        do {
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            let database = try SwiftDataAssignmentRepository.makeContainer(inMemory: testing)
            let repository = SwiftDataAssignmentRepository(container: database)
            store = try AssignmentStore(repository: repository)
            store?.defaultReminder = preferences.defaultReminder
            attachmentService = try? LocalAttachmentService()
            store?.didChange = { [weak self] in self?.refreshServices() }
            preferences.didChange = { [weak self] in
                guard let self else { return }
                self.store?.defaultReminder = self.preferences.defaultReminder
            }
            refreshServices()
            startupError = nil
        } catch {
            startupError = "Your data could not be opened. It has not been erased. \(error.localizedDescription)"
        }
    }

    func refreshServices() {
        guard let store else { return }
        notifications.refresh(store.assignments)
        if let attachmentService {
            let keeping = Set(store.assignments.filter { $0.deletedAt == nil }.flatMap(\.attachments).map(\.relativePath))
            Task { try? await attachmentService.pruneOrphans(keeping: keeping, now: Date()) }
        }
    }
}
