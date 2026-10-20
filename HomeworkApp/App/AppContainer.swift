import Foundation
import Observation
import HomeworkDomain

/// Composition root for replaceable platform services and shared window state.
@Observable @MainActor
final class AppContainer {
    let version = "0.1.0"
    private(set) var store: AssignmentStore?
    private(set) var startupError: String?
    let syncService: any SyncService = OfflineSyncService()
    let preferences = AppPreferences()
    let notifications = NotificationCoordinator(client: LocalNotificationClient())
    private(set) var attachmentService: (any AttachmentService)?
    private(set) var backupService: (any BackupService)?
    let secrets: any SecretStore = KeychainSecretStore()
    let providerBuilder: LLMProviderBuilder = { configuration, key in
        ChatCompletionsProvider(configuration: configuration, apiKey: key, transport: URLSessionTransport())
    }

    init() { openStore() }

    func openStore() {
        do {
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            let database = try SwiftDataAssignmentRepository.makeContainer(inMemory: testing)
            let repository = SwiftDataAssignmentRepository(container: database)
            store = try AssignmentStore(repository: repository)
            #if DEBUG
            if testing && ProcessInfo.processInfo.arguments.contains("--fixture-assignments") {
                try store?.save(UITestFixtures.assignments())
            }
            #endif
            store?.defaultReminder = preferences.defaultReminder
            attachmentService = try? LocalAttachmentService()
            if let attachmentService { backupService = LocalBackupService(attachments: attachmentService) }
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

    func makeLLMProvider() throws -> any LLMProvider {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--uitesting") && arguments.contains("--mock-ai") { return FixtureLLMProvider() }
        #endif
        _ = try preferences.provider.endpoint()
        guard let key = try secrets.readKey(), !key.isEmpty else { throw LLMError.missingKey }
        return providerBuilder(preferences.provider, key)
    }
}
