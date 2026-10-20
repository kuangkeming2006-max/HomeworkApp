import Foundation

public enum ReminderMessage {
    public static func body(deadline: Date, fireDate: Date) -> String {
        let seconds = max(0, deadline.timeIntervalSince(fireDate))
        let remaining: String
        if seconds >= 86400 { let days = Int((seconds / 86400).rounded()); remaining = "\(days) \(days == 1 ? "day" : "days")" }
        else if seconds >= 3600 { let hours = Int((seconds / 3600).rounded()); remaining = "\(hours) \(hours == 1 ? "hour" : "hours")" }
        else { let minutes = max(1, Int((seconds / 60).rounded())); remaining = "\(minutes) \(minutes == 1 ? "minute" : "minutes")" }
        return "You've got \(remaining) left. A little progress now goes a long way."
    }
}
