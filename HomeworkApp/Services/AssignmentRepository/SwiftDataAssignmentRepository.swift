import Foundation
import SwiftData
import HomeworkDomain

@MainActor
final class SwiftDataAssignmentRepository: AssignmentRepository {
    let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer) {
        self.container = container
        context = ModelContext(container)
        context.autosaveEnabled = false
    }

    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: HomeworkSchemaV1.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration("Homework", schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration("Homework", schema: schema,
                                               isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: HomeworkMigrationPlan.self,
                                  configurations: [configuration])
    }

    func fetchAll() throws -> [Assignment] {
        try context.fetch(FetchDescriptor<AssignmentEntity>()).map { try $0.record() }
    }

    func save(_ assignments: [Assignment]) throws {
        for assignment in assignments { try assignment.validate() }
        do {
            let existing = try context.fetch(FetchDescriptor<AssignmentEntity>())
            var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            for assignment in assignments {
                let entity: AssignmentEntity
                if let saved = byID[assignment.id] {
                    entity = saved
                } else {
                    entity = AssignmentEntity(id: assignment.id, title: assignment.title,
                                              dueDate: assignment.dueDate, now: assignment.createdAt)
                    context.insert(entity)
                    byID[assignment.id] = entity
                }
                try entity.apply(assignment)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

private extension AssignmentEntity {
    func record() throws -> Assignment {
        guard let priority = Priority(rawValue: priorityRaw),
              let unit = ReminderConfiguration.Unit(rawValue: reminderUnit) else {
            throw AssignmentError.invalid("A saved assignment uses an unsupported data value.")
        }
        var value = Assignment(id: id, title: title, course: course, notes: notes, dueDate: dueDate,
                               dueTimeZone: dueTimeZone, priority: priority,
                               reminder: .init(amount: reminderAmount, unit: unit), now: createdAt)
        value.isCompleted = isCompleted; value.completedAt = completedAt
        value.attachments = try JSONDecoder().decode([AttachmentReference].self, from: attachmentsData)
        value.updatedAt = updatedAt; value.deletedAt = deletedAt; value.localRevision = localRevision
        try value.validate()
        return value
    }

    func apply(_ value: Assignment) throws {
        title = value.title; course = value.course; notes = value.notes
        dueDate = value.dueDate; dueTimeZone = value.dueTimeZone
        priorityRaw = value.priority.rawValue
        isCompleted = value.isCompleted; completedAt = value.completedAt
        reminderAmount = value.reminder.amount; reminderUnit = value.reminder.unit.rawValue
        attachmentsData = try JSONEncoder().encode(value.attachments)
        createdAt = value.createdAt; updatedAt = value.updatedAt
        deletedAt = value.deletedAt; localRevision = value.localRevision
    }
}
