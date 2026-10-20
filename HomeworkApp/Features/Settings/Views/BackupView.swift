import SwiftUI
import UniformTypeIdentifiers
import HomeworkDomain

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct BackupView: View {
    @State private var model: BackupViewModel
    init(store: AssignmentStore, service: any BackupService) {
        _model = State(initialValue: BackupViewModel(store: store, service: service))
    }

    var body: some View {
        Form {
            Section {
                Button("Export backup", systemImage: "square.and.arrow.up") { Task { await model.export() } }
                    .accessibilityIdentifier("backup.export")
                Button("Import backup", systemImage: "square.and.arrow.down") { model.showImporter = true }
                    .accessibilityIdentifier("backup.import")
            } footer: {
                Text("Backups include all active and completed assignments and their attachments. API keys and provider settings are excluded. The JSON file is not encrypted; store it somewhere private. Maximum size: 100 MB.")
            }
            .disabled(model.busy)
            if model.archive != nil {
                Section("Review import") {
                    LabeledContent("New assignments", value: "\(model.newCount)")
                    LabeledContent("Already on this device", value: "\(model.skippedCount)")
                    Text("Existing assignments, including deleted records, are preserved. Only missing assignment IDs will be added.")
                    Button("Restore new assignments") { Task { await model.restore() } }
                        .disabled(model.busy || model.newCount == 0).accessibilityIdentifier("backup.restore")
                    Button("Cancel import", role: .cancel) { model.cancelImport() }.disabled(model.busy)
                }
            }
            if model.busy { ProgressView("Preparing backup…") }
            if let message = model.message { Section { Text(message).accessibilityIdentifier("backup.feedback") } }
        }
        .navigationTitle("Backup and restore")
        .fileExporter(isPresented: $model.showExporter, document: BackupDocument(data: model.exportData),
                      contentType: .json, defaultFilename: "Homework-backup") { result in
            switch result {
            case .success: model.message = "Backup exported."
            case .failure(let error): model.message = error.localizedDescription
            }
            model.exportData = Data()
        }
        .fileImporter(isPresented: $model.showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): Task { await model.read(url) }
            case .failure(let error): model.message = error.localizedDescription
            }
        }
    }
}
