import Foundation
import Observation
import HomeworkDomain

/// Composition root for replaceable platform services and shared window state.
@Observable @MainActor
final class AppContainer {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
    private(set) var store: AssignmentStore?
    private(set) var startupError: String?
    let syncService: any SyncService = OfflineSyncService()
    let preferences = AppPreferences()
    let notifications: NotificationCoordinator
    private let notificationClient: LocalNotificationClient
    let liveActivities = LiveActivityCoordinator(client: ActivityKitClient())
    let briefingHistory = BriefingHistoryStore()
    var pendingRoute: HomeworkRoute?
    private var foreground = true
    private var lastPrunedAt: Date?
    private let testing: Bool
    private(set) var attachmentService: (any AttachmentService)?
    private(set) var backupService: (any BackupService)?
    let secrets: any SecretStore = KeychainSecretStore()
    let providerBuilder: LLMProviderBuilder = { configuration, key in
        ChatCompletionsProvider(configuration: configuration, apiKey: key, transport: URLSessionTransport())
    }

    init(testing: Bool = ProcessInfo.processInfo.arguments.contains("--uitesting")) {
        self.testing = testing
        let client = LocalNotificationClient()
        notificationClient = client; notifications = NotificationCoordinator(client: client)
        client.onResponse = { [weak self] response in
            guard let self else { return }
            await self.handleNotificationAndWait(response)
        }
        liveActivities.didChange = { [weak self] in self?.refreshNotifications() }
        openStore()
    }

    func openStore() {
        do {
            let database = try SwiftDataAssignmentRepository.makeContainer(inMemory: testing)
            let repository = SwiftDataAssignmentRepository(container: database)
            store = try AssignmentStore(repository: repository)
            #if DEBUG
            if testing && ProcessInfo.processInfo.arguments.contains("--fixture-assignments") {
                try store?.save(UITestFixtures.assignments())
            }
            if testing && ProcessInfo.processInfo.arguments.contains("--fixture-performance") {
                try store?.save(UITestFixtures.performanceAssignments())
            }
            #endif
            store?.defaultReminder = preferences.defaultReminder
            attachmentService = try? LocalAttachmentService()
            if let attachmentService { backupService = LocalBackupService(attachments: attachmentService) }
            #if DEBUG
            if testing, ProcessInfo.processInfo.arguments.contains("--fixture-design"), let attachmentService {
                Task { @MainActor [weak self] in
                    do {
                        let values = try await UITestFixtures.designAssignments(service: attachmentService)
                        try self?.store?.save(values)
                    }
                    catch { self?.store?.errorMessage = "Synthetic fixture could not be loaded." }
                }
            }
            #endif
            store?.didChange = { [weak self] in self?.refreshServices() }
            preferences.didChange = { [weak self] in
                guard let self else { return }
                self.store?.defaultReminder = self.preferences.defaultReminder
                self.refreshServices()
            }
            refreshServices()
            startupError = nil
        } catch {
            startupError = "Your data could not be opened. It has not been erased. \(error.localizedDescription)"
        }
    }

    func refreshServices() {
        guard let store else { return }
        refreshNotifications()
        liveActivities.refresh(store.assignments, enabled: preferences.liveActivitiesEnabled, foreground: foreground)
        if !testing {
            briefingHistory.record(BriefingService.report(store.assignments, now: .now))
        }
        if let attachmentService, lastPrunedAt.map({ Date().timeIntervalSince($0) > 3600 }) ?? true {
            lastPrunedAt = Date()
            let keeping = Set(store.assignments.filter { $0.deletedAt == nil }.flatMap(\.attachments).map(\.relativePath))
            Task { try? await attachmentService.pruneOrphans(keeping: keeping, now: Date()) }
        }
    }

    func handleNotification(_ response: HomeworkNotificationResponse) {
        switch response {
        case .open(let route): pendingRoute = route
        case .complete(let id):
            notificationClient.remove(identifiers: ["assignment.\(id.uuidString)"])
            store?.setStatus(id, to: .completed)
        }
    }

    func handleNotificationAndWait(_ response: HomeworkNotificationResponse) async {
        handleNotification(response)
        // Finish OS-granted notification-action work before returning its completion callback.
        await liveActivities.waitUntilIdle()
        await notifications.waitUntilIdle()
    }

    func setForeground(_ active: Bool) {
        foreground = active
        if active { notificationClient.clearBadge(); refreshServices() }
        else if let store { liveActivities.refresh(store.assignments, enabled: preferences.liveActivitiesEnabled, foreground: false) }
    }

    private func refreshNotifications() {
        guard let store else { return }
        notifications.refresh(store.assignments, briefing: preferences.briefing, liveActivity: liveActivities.registeredPlan)
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
