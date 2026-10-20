import SwiftUI
import HomeworkDomain

struct AssignmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editor: AssignmentEditor
    @Environment(\.attachmentService) private var attachmentService
    private let store: AssignmentStore

    init(assignment: Assignment, isNew: Bool = false, store: AssignmentStore) {
        self.store = store
        _editor = State(initialValue: AssignmentEditor(assignment: assignment, isNew: isNew, store: store))
    }

    var body: some View {
        Form {
            Section("Assignment") {
                TextField("Title", text: binding(\.title))
                    .accessibilityIdentifier("editor.title")
                TextField("Course", text: optionalBinding(\.course))
                    .accessibilityIdentifier("editor.course")
                Picker("Priority", selection: binding(\.priority)) {
                    ForEach(Priority.allCases) { Text($0.label).tag($0) }
                }
                .accessibilityIdentifier("editor.priority")
            }
            Section("Deadline") {
                DatePicker("Deadline", selection: binding(\.dueDate), displayedComponents: [.date, .hourAndMinute])
                    .environment(\.timeZone, TimeZone(identifier: editor.draft.dueTimeZone) ?? .current)
                    .accessibilityIdentifier("editor.deadline")
                Picker("Time zone", selection: binding(\.dueTimeZone)) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { Text($0).tag($0) }
                }
                .accessibilityIdentifier("editor.timezone")
            }
            Section("Notes") {
                TextEditor(text: optionalBinding(\.notes)).frame(minHeight: 120)
                    .accessibilityLabel("Notes").accessibilityIdentifier("editor.notes")
            }
            Section("Reminder") {
                ReminderPicker(value: binding(\.reminder))
                Text("Enable notifications in Settings. A reminder time that has already passed will be skipped.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if editor.isNew {
                Section("Attachments") { Text("Create the assignment to add photos and files.").foregroundStyle(.secondary) }
            } else if let attachmentService {
                AttachmentList(assignmentID: editor.draft.id, store: store, service: attachmentService)
            } else {
                Section("Attachments") { Text("Attachment storage is currently unavailable.").foregroundStyle(.secondary) }
            }
            if !editor.isNew {
                Section {
                    Toggle("Completed", isOn: Binding(get: { editor.draft.isCompleted }, set: { editor.setCompleted($0) }))
                        .accessibilityIdentifier("editor.completed")
                    Picker("Status", selection: Binding(get: { editor.draft.status }, set: { editor.setStatus($0) })) {
                        ForEach(AssignmentStatus.allCases) { Text($0.label).tag($0) }
                    }.accessibilityIdentifier("editor.status")
                }
            }
            Section {
                if let message = editor.validationMessage { Text(message).foregroundStyle(.red) }
                else if !editor.isNew { Text("Changes save automatically.").foregroundStyle(.secondary) }
            }
        }
        .navigationTitle(editor.isNew ? "New assignment" : "Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("editor.form")
        .toolbar {
            if editor.isNew {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { if editor.create() { dismiss() } }
                        .disabled(!editor.canSave).accessibilityIdentifier("editor.save")
                }
            }
        }
        .onDisappear { editor.flush() }
    }

    private func binding<Value>(_ path: WritableKeyPath<Assignment, Value>) -> Binding<Value> {
        Binding(get: { editor.draft[keyPath: path] }, set: { editor.set(path, $0) })
    }

    private func optionalBinding(_ path: WritableKeyPath<Assignment, String?>) -> Binding<String> {
        Binding(get: { editor.draft[keyPath: path] ?? "" }, set: { editor.set(path, $0.isEmpty ? nil : $0) })
    }
}
