import Foundation

public struct PlannedReminder: Equatable, Sendable {
    public let assignmentID: UUID
    public let title: String
    public let course: String?
    public let dueDate: Date
    public let fireDate: Date
    public let timeZone: String
    public var identifier: String { "assignment.\(assignmentID.uuidString)" }
}

public struct ReminderPlan: Sendable {
    public let scheduled: [PlannedReminder]
    public let deferredCount: Int
    public let pastCount: Int

    public init(assignments: [Assignment], now: Date, capacity: Int = 60) {
        var candidates: [PlannedReminder] = []
        var past = 0
        for assignment in assignments where assignment.status == .active && assignment.deletedAt == nil {
            guard (try? assignment.validate()) != nil,
                  let zone = TimeZone(identifier: assignment.dueTimeZone),
                  let fire = assignment.reminder.fireDate(dueDate: assignment.dueDate, timeZone: zone) else { continue }
            guard fire > now else { past += 1; continue }
            candidates.append(PlannedReminder(assignmentID: assignment.id, title: assignment.title,
                                               course: assignment.course, dueDate: assignment.dueDate,
                                               fireDate: fire, timeZone: assignment.dueTimeZone))
        }
        candidates.sort {
            $0.fireDate == $1.fireDate ? $0.assignmentID.uuidString < $1.assignmentID.uuidString : $0.fireDate < $1.fireDate
        }
        let limit = min(60, max(0, capacity))
        scheduled = Array(candidates.prefix(limit))
        deferredCount = max(0, candidates.count - limit)
        pastCount = past
    }
}

public enum NotificationPermission: String, Sendable {
    case notDetermined, allowed, denied
}

@MainActor
public protocol ReminderNotificationClient {
    func permission() async -> NotificationPermission
    func requestPermission() async throws -> Bool
    func pendingIdentifiers() async -> [String]
    func remove(identifiers: [String])
    func add(_ reminder: PlannedReminder) async throws
}
