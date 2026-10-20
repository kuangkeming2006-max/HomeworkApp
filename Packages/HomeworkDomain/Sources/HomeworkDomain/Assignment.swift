import Foundation

public struct Assignment: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var course: String?
    public var notes: String?
    public var dueDate: Date
    public var dueTimeZone: String
    public var priority: Priority
    public var status: AssignmentStatus
    /// Compatibility for version-one clients and backups. Status is the source of truth.
    public var isCompleted: Bool {
        get { status == .completed }
        set { status = newValue ? .completed : .active }
    }
    public var completedAt: Date?
    public var abandonedAt: Date?
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
        self.status = .active
        self.completedAt = nil
        self.abandonedAt = nil
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
        guard isCompleted == (completedAt != nil), (status == .abandoned) == (abandonedAt != nil), localRevision > 0 else {
            throw AssignmentError.invalid("The assignment has inconsistent completion information.")
        }
        guard createdAt.timeIntervalSince1970.isFinite, updatedAt.timeIntervalSince1970.isFinite,
              updatedAt >= createdAt, completedAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true,
              abandonedAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true,
              deletedAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true,
              attachments.count <= 100, Set(attachments.map(\.id)).count == attachments.count else {
            throw AssignmentError.invalid("The assignment has invalid timestamps or attachment information.")
        }
        for attachment in attachments { try attachment.validate() }
        try reminder.validate()
    }

    public mutating func transition(to target: AssignmentStatus, at date: Date) {
        status = target
        completedAt = target == .completed ? max(date, createdAt) : nil
        abandonedAt = target == .abandoned ? max(date, createdAt) : nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, course, notes, dueDate, dueTimeZone, priority, status, isCompleted, completedAt,
             abandonedAt, reminder, attachments, createdAt, updatedAt, deletedAt, localRevision
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        course = try c.decodeIfPresent(String.self, forKey: .course)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        dueDate = try c.decode(Date.self, forKey: .dueDate)
        dueTimeZone = try c.decode(String.self, forKey: .dueTimeZone)
        priority = try c.decode(Priority.self, forKey: .priority)
        let legacyCompleted = try c.decode(Bool.self, forKey: .isCompleted)
        status = try c.decodeIfPresent(AssignmentStatus.self, forKey: .status) ?? (legacyCompleted ? .completed : .active)
        guard legacyCompleted == (status == .completed) else {
            throw DecodingError.dataCorruptedError(forKey: .status, in: c, debugDescription: "Inconsistent assignment status.")
        }
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        abandonedAt = try c.decodeIfPresent(Date.self, forKey: .abandonedAt)
        reminder = try c.decode(ReminderConfiguration.self, forKey: .reminder)
        attachments = try c.decode([AttachmentReference].self, forKey: .attachments)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        localRevision = try c.decode(Int.self, forKey: .localRevision)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(title, forKey: .title)
        try c.encodeIfPresent(course, forKey: .course); try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(dueDate, forKey: .dueDate); try c.encode(dueTimeZone, forKey: .dueTimeZone)
        try c.encode(priority, forKey: .priority); try c.encode(status, forKey: .status)
        try c.encode(isCompleted, forKey: .isCompleted); try c.encodeIfPresent(completedAt, forKey: .completedAt)
        try c.encodeIfPresent(abandonedAt, forKey: .abandonedAt); try c.encode(reminder, forKey: .reminder)
        try c.encode(attachments, forKey: .attachments); try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt); try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encode(localRevision, forKey: .localRevision)
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
