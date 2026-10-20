import Foundation
import UserNotifications
import HomeworkDomain

private final class NotificationPresentationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@MainActor
final class LocalNotificationClient: ReminderNotificationClient {
    private let center = UNUserNotificationCenter.current()
    private let presentationDelegate = NotificationPresentationDelegate()

    init() { center.delegate = presentationDelegate }

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
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func remove(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func add(_ reminder: PlannedReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.subtitle = reminder.course ?? "Assignment reminder"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: reminder.timeZone)
        formatter.dateStyle = .medium; formatter.timeStyle = .short
        content.body = "Due \(formatter.string(from: reminder.dueDate))."
        content.sound = .default
        content.userInfo = ["assignmentID": reminder.assignmentID.uuidString]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.fireDate)
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
    }
}
