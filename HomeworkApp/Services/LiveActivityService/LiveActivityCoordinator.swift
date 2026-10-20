import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class LiveActivityCoordinator {
    private let client: any LiveActivityClient
    private var latest: [Assignment] = []
    private var enabled = false
    private var foreground = true
    private var version = 0
    private var worker: Task<Void, Never>?
    private(set) var registeredPlan: LiveActivityPlan?
    private(set) var available = false
    private(set) var status = "Disabled"
    private(set) var errorMessage: String?
    var didChange: (() -> Void)?

    init(client: any LiveActivityClient) { self.client = client }

    func refresh(_ assignments: [Assignment], enabled: Bool, foreground: Bool) {
        latest = assignments; self.enabled = enabled; self.foreground = foreground; version += 1
        guard worker == nil else { return }
        worker = Task { @MainActor [weak self] in
            await self?.reconcile()
            self?.worker = nil
        }
    }
    func waitUntilIdle() async { await worker?.value }

    private func reconcile() async {
        var processed = -1
        while processed != version {
            processed = version
            available = client.available
            let now = Date()
            let plan = enabled && available ? LiveActivityPlan.next(latest, now: now) : nil
            let existing = client.activities
            let keep = plan.flatMap { plan in
                existing.first { activity in
                    guard activity.assignmentID == plan.assignmentID, activity.state != .ended else { return false }
                    if activity.state == .pending { return activity.matches(plan) }
                    return plan.start <= now
                }
            }
            for activity in existing where activity.id != keep?.id { await client.end(activity.id) }
            registeredPlan = nil
            guard let plan else {
                status = enabled ? (available ? "No eligible deadline" : "Unavailable in system settings") : "Disabled"
                errorMessage = nil; didChange?(); continue
            }
            if let keep {
                if !keep.matches(plan) { await client.update(keep.id, plan: plan) }
                registeredPlan = plan; status = keep.state == .pending ? "Scheduled" : "Counting down"
                errorMessage = nil
            } else if foreground {
                do {
                    try client.request(plan, now: now)
                    registeredPlan = plan; status = plan.start > now ? "Scheduled" : "Counting down"
                    errorMessage = nil
                } catch {
                    status = "Using ordinary reminders"
                    errorMessage = "The system could not start this Live Activity. Deadline notifications remain available."
                }
            } else { status = "Open the app to schedule" }
            didChange?()
        }
    }
}
