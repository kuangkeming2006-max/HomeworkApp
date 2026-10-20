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
    private var briefing = BriefingConfiguration()
    private var quietActivity: LiveActivityPlan?
    private var knownReminders: [String: PlannedReminder] = [:]
    private var knownBriefings: [String: PlannedBriefing] = [:]
    private var cancelledTerminalIDs: Set<String> = []
    private(set) var briefingCount = 0
    private var version = 0
    private var worker: Task<Void, Never>?

    init(client: any ReminderNotificationClient) { self.client = client }

    func refresh(_ assignments: [Assignment], briefing: BriefingConfiguration = .init(), liveActivity: LiveActivityPlan? = nil) {
        latest = assignments; self.briefing = briefing; quietActivity = liveActivity; version += 1
        guard worker == nil else { return }
        worker = Task { @MainActor [weak self] in
            await self?.processChanges()
            self?.worker = nil
        }
    }

    func waitUntilIdle() async { await worker?.value }

    func enable() async {
        do { if await client.permission() == .notDetermined { _ = try await client.requestPermission() } }
        catch { errorMessage = "Notification permission could not be requested. Try again in system Settings." }
        refresh(latest, briefing: briefing, liveActivity: quietActivity)
        await waitUntilIdle()
    }

    private func processChanges() async {
        var processed = -1
        while processed != version {
            processed = version
            let assignments = latest
            permission = await client.permission()
            let allPending = await client.pendingIdentifiers()
            let existing = allPending.filter { $0.hasPrefix("assignment.") || $0.hasPrefix("briefing.") }
            let reserved = allPending.count - existing.count
            let summaries = client is any BriefingNotificationClient ? Array(BriefingService.plan(assignments, configuration: briefing, now: Date()).prefix(max(0, 60 - reserved))) : []
            let plan = ReminderPlan(assignments: assignments, now: Date(), capacity: max(0, 60 - reserved - summaries.count))
            // A successfully registered Live Activity owns only an exactly coincident alert.
            // Earlier multi-day reminders and failures keep their ordinary notification fallback.
            let reminders = plan.scheduled.filter { reminder in
                guard let activity = quietActivity else { return true }
                return reminder.assignmentID != activity.assignmentID || abs(reminder.fireDate.timeIntervalSince(activity.start)) > 1
            }
            let desired = permission == .allowed ? Set(reminders.map(\.identifier) + summaries.map(\.identifier)) : []
            let terminalIDs = Set(assignments.filter { $0.status != .active || $0.deletedAt != nil }.map { "assignment.\($0.id.uuidString)" })
            let obsolete = Set(existing.filter { !desired.contains($0) }).union(terminalIDs.subtracting(cancelledTerminalIDs))
            if !obsolete.isEmpty { client.remove(identifiers: Array(obsolete)) }
            cancelledTerminalIDs = terminalIDs
            knownReminders = knownReminders.filter { desired.contains($0.key) }
            knownBriefings = knownBriefings.filter { desired.contains($0.key) }
            scheduledCount = 0; briefingCount = 0; deferredCount = plan.deferredCount; pastCount = plan.pastCount
            guard permission == .allowed else { continue }
            do {
                for reminder in reminders {
                    if processed != version { break }
                    if knownReminders[reminder.identifier] != reminder || !allPending.contains(reminder.identifier) {
                        if let previous = knownReminders[reminder.identifier], previous != reminder {
                            client.remove(identifiers: [reminder.identifier])
                        }
                        try await client.add(reminder); knownReminders[reminder.identifier] = reminder
                    }
                    scheduledCount += 1
                }
                if let summaryClient = client as? any BriefingNotificationClient {
                    for summary in summaries {
                        if processed != version { break }
                        if knownBriefings[summary.identifier] != summary || !allPending.contains(summary.identifier) {
                            try await summaryClient.addBriefing(summary); knownBriefings[summary.identifier] = summary
                        }
                        briefingCount += 1
                    }
                }
                errorMessage = nil
            } catch {
                errorMessage = "Some reminders could not be scheduled. Open the app to try again."
            }
        }
    }
}
