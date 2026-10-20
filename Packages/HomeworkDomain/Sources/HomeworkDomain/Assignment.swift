import Foundation

public struct Assignment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var course: String?
    public var notes: String?
    public var dueDate: Date
    public var dueTimeZone: String
    public var priority: Priority
    public var isCompleted: Bool
    public var completedAt: Date?
    public var reminder: ReminderConfiguration
    public var attachments: [AttachmentReference]
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    public var localRevision: Int

    public init(id: UUID = UUID(), title: String = "", course: String? = nil,
                notes: String? = nil, dueDate: Date, dueTimeZone: String = TimeZone.current.identifier,
                priority: Priority = .medium, reminder: ReminderConfiguration = .none,
                now: Date = Date()) {
        self.id = id
        self.title = title
        self.course = course
        self.notes = notes
        self.dueDate = dueDate
        self.dueTimeZone = dueTimeZone
        self.priority = priority
        self.reminder = reminder
        self.isCompleted = false
        self.completedAt = nil
        self.attachments = []
        self.createdAt = now
        self.updatedAt = now
        self.deletedAt = nil
        self.localRevision = 1
    }

    public func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssignmentError.invalid("Enter an assignment title.")
        }
        guard title.count <= 500, (course?.count ?? 0) <= 200, (notes?.count ?? 0) <= 50_000 else {
            throw AssignmentError.invalid("The title, course or notes are too long.")
        }
        guard dueDate.timeIntervalSince1970.isFinite, TimeZone(identifier: dueTimeZone) != nil else {
            throw AssignmentError.invalid("Choose a valid deadline and time zone.")
        }
        guard isCompleted == (completedAt != nil), localRevision > 0 else {
            throw AssignmentError.invalid("The assignment has inconsistent completion information.")
        }
        guard createdAt.timeIntervalSince1970.isFinite, updatedAt.timeIntervalSince1970.isFinite,
              updatedAt >= createdAt, completedAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true,
              deletedAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true,
              attachments.count <= 100, Set(attachments.map(\.id)).count == attachments.count else {
            throw AssignmentError.invalid("The assignment has invalid timestamps or attachment information.")
        }
        for attachment in attachments { try attachment.validate() }
        try reminder.validate()
    }
}

public struct AttachmentReference: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var relativePath: String
    public var contentType: String
    public var byteCount: Int
    public var sha256: String
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, relativePath: String, contentType: String,
                byteCount: Int, sha256: String, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.relativePath = relativePath
        self.contentType = contentType; self.byteCount = byteCount
        self.sha256 = sha256; self.createdAt = createdAt
    }

    public func validate() throws {
        guard !name.isEmpty, name.count <= 255, !relativePath.isEmpty, relativePath.count <= 255,
              relativePath != ".", relativePath != "..", !relativePath.contains("/"), !relativePath.contains("\\"),
              !contentType.isEmpty, contentType.count <= 200, byteCount > 0, byteCount <= 25 * 1024 * 1024,
              sha256.count == 64, sha256.allSatisfy({ $0.isASCII && $0.isHexDigit }),
              createdAt.timeIntervalSince1970.isFinite else {
            throw AssignmentError.invalid("The attachment metadata is invalid.")
        }
    }
}

public enum AssignmentError: LocalizedError, Equatable, Sendable {
    case invalid(String)
    case notFound

    public var errorDescription: String? {
        switch self {
        case .invalid(let message): message
        case .notFound: "This assignment is no longer available."
        }
    }
}
