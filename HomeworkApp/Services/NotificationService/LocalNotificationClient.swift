import Foundation
import UserNotifications
import HomeworkDomain

enum HomeworkNotificationResponse: Sendable { case open(HomeworkRoute), complete(UUID) }

@MainActor
private final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onResponse: ((HomeworkNotificationResponse) -> Void)?
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        let identifier = response.notification.request.content.userInfo["assignmentID"] as? String
        let briefing = response.notification.request.content.userInfo["route"] as? String == "briefing"
        await respond(action: action, identifier: identifier, briefing: briefing)
    }

    private func respond(action: String, identifier: String?, briefing: Bool) {
        guard [UNNotificationDefaultActionIdentifier, "assignment.complete", "assignment.view"].contains(action) else { return }
        if let identifier, let id = UUID(uuidString: identifier) {
            onResponse?(action == "assignment.complete" ? .complete(id) : .open(.assignment(id)))
        } else if briefing { onResponse?(.open(.briefing)) }
    }
}

@MainActor
final class LocalNotificationClient: BriefingNotificationClient {
    private let center = UNUserNotificationCenter.current()
    private let presentationDelegate = NotificationPresentationDelegate()
    var onResponse: ((HomeworkNotificationResponse) -> Void)? {
        didSet { presentationDelegate.onResponse = onResponse }
    }

    init() {
        center.delegate = presentationDelegate
        let complete = UNNotificationAction(identifier: "assignment.complete", title: "Complete", options: [])
        let view = UNNotificationAction(identifier: "assignment.view", title: "View assignment", options: [.foreground])
        center.setNotificationCategories([UNNotificationCategory(identifier: "assignment", actions: [complete, view], intentIdentifiers: [])])
    }

    func permission() async -> NotificationPermission {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .allowed
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async throws -> Bool {
        guard await permission() == .notDetermined else { return await permission() == .allowed }
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func clearBadge() { Task { try? await center.setBadgeCount(0) } }

    func remove(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func add(_ reminder: PlannedReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.subtitle = reminder.course ?? "Assignment reminder"
        content.body = ReminderMessage.body(deadline: reminder.dueDate, fireDate: reminder.fireDate)
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "assignment"
        content.threadIdentifier = "assignment.\(reminder.assignmentID)"
        content.userInfo = ["assignmentID": reminder.assignmentID.uuidString]
        try await schedule(identifier: reminder.identifier, content: content, fireDate: reminder.fireDate)
    }

    func addBriefing(_ briefing: PlannedBriefing) async throws {
        let content = UNMutableNotificationContent()
        content.title = briefing.title; content.body = briefing.body; content.sound = .default
        content.userInfo = ["route": "briefing"]; content.threadIdentifier = "briefing"
        try await schedule(identifier: briefing.identifier, content: content, fireDate: briefing.fireDate)
    }

    private func schedule(identifier: String, content: UNMutableNotificationContent, fireDate: Date) async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
