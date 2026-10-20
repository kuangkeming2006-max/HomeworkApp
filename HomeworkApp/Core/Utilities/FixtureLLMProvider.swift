#if DEBUG
import Foundation
import HomeworkDomain

struct FixtureLLMProvider: LLMProvider {
    func extract(_ input: LLMInput, context: ImportContext) async throws -> [ImportCandidate] {
        let due = ISO8601DateFormatter().string(from: context.now.addingTimeInterval(3 * 86_400))
        let object: [String: Any] = ["assignments": [
            ["title": "AI networking lab", "course": "Computer networks", "notes": "Synthetic UI test fixture",
             "dueDate": due, "dueTimeZone": "UTC", "priority": 1, "reminderAmount": 2,
             "reminderUnit": "days", "needsDateConfirmation": false, "dateIssue": NSNull()],
            ["title": "Ambiguous seminar", "course": NSNull(), "notes": NSNull(),
             "dueDate": NSNull(), "dueTimeZone": "UTC", "priority": 3, "reminderAmount": NSNull(),
             "reminderUnit": NSNull(), "needsDateConfirmation": true, "dateIssue": "Choose and confirm the deadline."]]]
        return try AssignmentJSONParser.parse(JSONSerialization.data(withJSONObject: object), context: context)
    }
    func testConnection() async throws -> String { "Synthetic connection succeeded." }
}
#endif
