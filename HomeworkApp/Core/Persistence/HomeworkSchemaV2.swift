import Foundation
import SwiftData

// V1 remains frozen. Optional new columns allow migration before values are backfilled.
enum HomeworkSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }
    static var models: [any PersistentModel.Type] { [AssignmentEntity.self] }

    @Model
    final class AssignmentEntity {
        @Attribute(.unique) var id: UUID
        var title: String
        var course: String?
        var notes: String?
        var dueDate: Date
        var dueTimeZone: String
        var priorityRaw: Int
        var isCompleted: Bool
        var completedAt: Date?
        var statusRaw: String?
        var abandonedAt: Date?
        var reminderAmount: Int
        var reminderUnit: String
        var attachmentsData: Data
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?
        var localRevision: Int

        init(id: UUID, title: String, dueDate: Date, now: Date) {
            self.id = id; self.title = title; self.dueDate = dueDate
            self.dueTimeZone = TimeZone.current.identifier
            self.priorityRaw = 3; self.isCompleted = false; self.statusRaw = "active"
            self.reminderAmount = 0; self.reminderUnit = "minutes"
            self.attachmentsData = Data("[]".utf8)
            self.createdAt = now; self.updatedAt = now; self.localRevision = 1
        }
    }
}

enum HomeworkMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [HomeworkSchemaV1.self, HomeworkSchemaV2.self] }
    static var stages: [MigrationStage] {
        [.custom(fromVersion: HomeworkSchemaV1.self, toVersion: HomeworkSchemaV2.self,
                 willMigrate: nil, didMigrate: { context in
            for entity in try context.fetch(FetchDescriptor<HomeworkSchemaV2.AssignmentEntity>()) {
                entity.statusRaw = entity.isCompleted ? "completed" : "active"
            }
            try context.save()
        })]
    }
}

typealias AssignmentEntity = HomeworkSchemaV2.AssignmentEntity
