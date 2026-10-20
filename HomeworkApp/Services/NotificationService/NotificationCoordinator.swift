import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class NotificationCoordinator {
    private(set) var permission: NotificationPermission = .notDetermined
    private(set) var scheduledCount = 0
    private(set) var deferredCount = 0
    private(set) var pastCount = 0
    private(set) var errorMessage: String?
    private let client: any ReminderNotificationClient
    private var latest: [Assignment] = []
    private var version = 0
    private var worker: Task<Void, Never>?

    init(client: any ReminderNotificationClient) { self.client = client }

    func refresh(_ assignments: [Assignment]) {
        latest = assignments; version += 1
        guard worker == nil else { return }
        worker = Task { @MainActor [weak self] in
            await self?.processChanges()
            self?.worker = nil
        }
    }

    func waitUntilIdle() async { await worker?.value }

    func enable() async {
        do { _ = try await client.requestPermission() }
        catch { errorMessage = "Notification permission could not be requested. Try again in system Settings." }
        refresh(latest)
        await waitUntilIdle()
    }

    private func processChanges() async {
        var processed = -1
        while processed != version {
            processed = version
            let assignments = latest
            permission = await client.permission()
            let allPending = await client.pendingIdentifiers()
            let existing = allPending.filter { $0.hasPrefix("assignment.") }
            let reserved = allPending.count - existing.count
            let plan = ReminderPlan(assignments: assignments, now: Date(), capacity: max(0, 60 - reserved))
            client.remove(identifiers: Array(Set(existing + assignments.map { "assignment.\($0.id.uuidString)" })))
            scheduledCount = 0; deferredCount = plan.deferredCount; pastCount = plan.pastCount
            guard permission == .allowed else { continue }
            do {
                for reminder in plan.scheduled {
                    if processed != version { break }
                    try await client.add(reminder)
                    scheduledCount += 1
                }
                errorMessage = nil
            } catch {
                errorMessage = "Some reminders could not be scheduled. Open the app to try again."
            }
        }
    }
}
