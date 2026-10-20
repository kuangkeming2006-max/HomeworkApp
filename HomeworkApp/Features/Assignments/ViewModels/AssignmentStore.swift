import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AssignmentStore {
    private(set) var assignments: [Assignment]
    var errorMessage: String?
    private let repository: any AssignmentRepository
    var didChange: (@MainActor () -> Void)?

    init(repository: any AssignmentRepository) throws {
        self.repository = repository
        assignments = try repository.fetchAll()
    }

    func assignment(_ id: UUID) -> Assignment? {
        assignments.first { $0.id == id && $0.deletedAt == nil }
    }

    func makeDraft(on day: Date? = nil) -> Assignment {
        let calendar = Calendar.current
        let target = day ?? calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let due = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: target) ?? target
        return Assignment(dueDate: due)
    }

    func save(_ values: [Assignment]) throws {
        try repository.save(values)
        assignments = try repository.fetchAll()
        didChange?()
    }

    func update(_ id: UUID, change: (inout Assignment) -> Void) throws {
        guard var value = assignment(id) else { throw AssignmentError.notFound }
        change(&value)
        value.updatedAt = max(Date(), value.updatedAt.addingTimeInterval(0.001))
        value.localRevision += 1
        try save([value])
    }

    func toggleCompletion(_ id: UUID) {
        perform {
            try update(id) {
                $0.isCompleted.toggle()
                $0.completedAt = $0.isCompleted ? max(Date(), $0.createdAt) : nil
            }
        }
    }

    func delete(_ id: UUID) {
        perform { try update(id) { $0.deletedAt = max(Date(), $0.updatedAt) } }
    }

    func perform(_ work: () throws -> Void) {
        do { try work() } catch { errorMessage = error.localizedDescription }
    }
}
