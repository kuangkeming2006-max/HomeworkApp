import Foundation

public enum AssignmentJSONParser {
    private struct Envelope: Decodable { let assignments: [Item] }
    private struct Item: Decodable {
        let title: String
        let course: String?
        let notes: String?
        let dueDate: String?
        let dueTimeZone: String
        let priority: Int
        let reminderAmount: Int?
        let reminderUnit: String?
        let needsDateConfirmation: Bool
        let dateIssue: String?
    }

    public static func parse(_ data: Data, context: ImportContext) throws -> [ImportCandidate] {
        guard data.count <= 1_048_576,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(root.keys) == ["assignments"], let items = root["assignments"] as? [[String: Any]],
              items.count <= 20 else { throw LLMError.schema }
        let keys: Set<String> = ["title", "course", "notes", "dueDate", "dueTimeZone", "priority",
                                 "reminderAmount", "reminderUnit", "needsDateConfirmation", "dateIssue"]
        guard items.allSatisfy({ Set($0.keys) == keys }) else { throw LLMError.schema }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch { throw LLMError.schema }
        return try envelope.assignments.map { item in
            guard let priority = Priority(rawValue: item.priority), TimeZone(identifier: item.dueTimeZone) != nil else {
                throw LLMError.schema
            }
            var reminder = context.defaultReminder
            if let amount = item.reminderAmount {
                guard let raw = item.reminderUnit, let unit = ReminderConfiguration.Unit(rawValue: raw) else { throw LLMError.schema }
                reminder = .init(amount: amount, unit: unit)
            } else if item.reminderUnit != nil { throw LLMError.schema }
            var date: Date?
            var offsetMismatch = false
            if let raw = item.dueDate {
                guard raw.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$"#,
                                options: .regularExpression) != nil else { throw LLMError.schema }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                date = formatter.date(from: raw)
                if date == nil { formatter.formatOptions = [.withInternetDateTime]; date = formatter.date(from: raw) }
                guard date != nil else { throw LLMError.schema }
                if let parsed = date, let zone = TimeZone(identifier: item.dueTimeZone) {
                    let suffix = String(raw.suffix(6))
                    let reportedOffset: Int
                    if raw.hasSuffix("Z") { reportedOffset = 0 }
                    else {
                        let numbers = suffix.dropFirst().split(separator: ":").compactMap { Int($0) }
                        guard numbers.count == 2, numbers[0] <= 23, numbers[1] <= 59 else { throw LLMError.schema }
                        reportedOffset = (numbers[0] * 3600 + numbers[1] * 60) * (suffix.first == "-" ? -1 : 1)
                    }
                    offsetMismatch = reportedOffset != zone.secondsFromGMT(for: parsed)
                }
            }
            let past = date.map { $0 < context.now } ?? false
            let uncertain = item.needsDateConfirmation || date == nil || past || offsetMismatch || !(item.dateIssue ?? "").isEmpty
            let value = Assignment(title: item.title, course: item.course, notes: item.notes,
                                   dueDate: date ?? context.now, dueTimeZone: item.dueTimeZone,
                                   priority: priority, reminder: reminder, now: context.now)
            do { try value.validate() } catch { throw LLMError.schema }
            return ImportCandidate(assignment: value, requiresDateConfirmation: uncertain,
                dateIssue: item.dateIssue ?? (date == nil ? "Choose and confirm the deadline." :
                    (offsetMismatch ? "The reported UTC offset differs from this time zone. Check and confirm the deadline." :
                        (past ? "This deadline is in the past. Confirm the date." : nil))))
        }
    }
}
