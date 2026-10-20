import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class BackupViewModel {
    private let store: AssignmentStore
    private let service: any BackupService
    private(set) var busy = false
    private(set) var archive: BackupArchive?
    var message: String?
    var exportData = Data()
    var showExporter = false
    var showImporter = false

    init(store: AssignmentStore, service: any BackupService) {
        self.store = store; self.service = service
    }

    var newCount: Int { archive?.newAssignments(existingIDs: Set(store.assignments.map(\.id))).count ?? 0 }
    var skippedCount: Int { (archive?.assignments.count ?? 0) - newCount }

    func export() async {
        guard !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do { exportData = try await service.export(store.assignments); showExporter = true }
        catch { message = error.localizedDescription }
    }

    func read(_ url: URL) async {
        guard !busy else { return }
        busy = true; message = nil; archive = nil
        defer { busy = false }
        do { archive = try await service.read(from: url) }
        catch { message = error.localizedDescription }
    }

    func cancelImport() { archive = nil }

    func restore() async {
        guard !busy, let archive else { return }
        busy = true; message = nil
        defer { busy = false }
        do {
            let batch = try await service.stage(archive, excluding: Set(store.assignments.map(\.id)))
            do {
                // Recheck after file IO: another window may have imported these UUIDs in the meantime.
                let existing = Set(store.assignments.map(\.id))
                let values = batch.assignments.filter { !existing.contains($0.id) }
                try store.save(values)
                let used = Set(values.flatMap(\.attachments).map(\.id))
                await service.discard(batch.createdFiles.filter { !used.contains($0.id) })
                self.archive = nil
                message = "Restored \(values.count) assignments. Existing assignments were preserved."
            } catch {
                await service.discard(batch.createdFiles)
                throw error
            }
        } catch { message = error.localizedDescription }
    }
}
