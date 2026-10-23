import SwiftUI
import HomeworkDomain

struct AssignmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editor: AssignmentEditor
    @State private var attachmentModel: AttachmentViewModel?
    @State private var closing = false
    @State private var confirmingExit = false
    @Environment(\.attachmentService) private var attachmentService
    private let store: AssignmentStore

    init(assignment: Assignment, isNew: Bool = false, store: AssignmentStore) {
        self.store = store
        _editor = State(initialValue: AssignmentEditor(assignment: assignment, isNew: isNew, store: store))
    }

    var body: some View {
        Form {
            Section("Assignment") {
                TextField("Title", text: binding(\.title), axis: .vertical)
                    .accessibilityIdentifier("editor.title")
                TextField("Course", text: optionalBinding(\.course), axis: .vertical)
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
                NavigationLink {
                    TimeZoneSelector(selection: binding(\.dueTimeZone))
                } label: { LabeledContent("Time zone", value: editor.draft.dueTimeZone) }
                .accessibilityIdentifier("editor.timezone")
            }
            Section("Notes") {
                TextEditor(text: optionalBinding(\.notes)).frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if editor.draft.notes?.isEmpty != false {
                            Text("Add notes or instructions…").foregroundStyle(.tertiary)
                                .padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("Notes").accessibilityIdentifier("editor.notes")
            }
            Section("Reminder") {
                ReminderPicker(value: binding(\.reminder))
                Text("Notifications follow your system settings. Reminder times that have already passed are skipped.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let attachmentModel {
                AttachmentList(model: attachmentModel)
            } else {
                Section("Attachments") { Text("Attachment storage is currently unavailable.").foregroundStyle(.secondary) }
            }
            if !editor.isNew {
                Section {
                    NativeToggleRow(title: "Completed", isOn: Binding(get: { editor.draft.isCompleted }, set: { editor.setCompleted($0) }), identifier: "editor.completed")
                        .disabled(editor.draft.status == .abandoned)
                    Picker("Status", selection: Binding(get: { editor.draft.status }, set: { editor.setStatus($0) })) {
                        ForEach(AssignmentStatus.allCases) { Text($0.label).tag($0).disabled(!editor.draft.status.canTransition(to: $0)) }
                    }.accessibilityIdentifier("editor.status")
                }
            }
            Section {
                if let message = editor.validationMessage { Text(message).foregroundStyle(.red) }
            }
        }
        .navigationTitle(editor.isNew ? "New assignment" : "Assignment")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("editor.form")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark", action: saveAndExit)
                    .disabled(closing || !editor.canSave || attachmentModel?.busy == true)
                    .accessibilityIdentifier("editor.save")
            }
        }
        .background(EditorDismissalGuard(needsConfirmation: editor.hasChanges || closing || attachmentModel?.busy == true,
                                         onAttempt: requestExit))
        .alert("Save changes?", isPresented: $confirmingExit) {
            Button("Save", action: saveAndExit).disabled(!editor.canSave || attachmentModel?.busy == true)
            Button("Discard Changes", role: .destructive, action: discardAndExit)
            Button("Keep Editing", role: .cancel) {}
        } message: { Text("Your changes have not been saved.") }
        // Presentation belongs to the stable Form, not its virtualized Section cells.
        .attachmentPreview(attachmentModel?.previewPresentation ?? unavailablePreview)
        .confirmationDialog("Remove attachment?", isPresented: Binding(
            get: { attachmentModel?.pendingRemoval != nil },
            set: { if !$0 { attachmentModel?.pendingRemoval = nil } }),
            titleVisibility: .visible, presenting: attachmentModel?.pendingRemoval) { reference in
                Button("Remove attachment", role: .destructive) {
                    Task { await attachmentModel?.remove(reference) }
                }.tint(.red)
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This removes the attachment from this assignment.")
            }
        .task {
            guard attachmentModel == nil, let attachmentService else { return }
            let draftEditor = editor
            attachmentModel = AttachmentViewModel(service: attachmentService, references: editor.draft.attachments) { [draftEditor] references in
                draftEditor.set(\.attachments, references)
            }
        }
        .onChange(of: store.assignment(editor.draft.id)) { _, value in
            if let value { editor.reconcile(value) }
        }
    }

    @State private var unavailablePreview = AttachmentPreviewModel()

    private func requestExit() {
        guard !closing, attachmentModel?.busy != true else { return }
        if editor.hasChanges { confirmingExit = true } else { discardAndExit() }
    }

    private func discardAndExit() {
        guard !closing else { return }
        closing = true
        Task { await attachmentModel?.close(); dismiss() }
    }

    private func saveAndExit() {
        guard !closing, attachmentModel?.busy != true else { return }
        guard editor.save() else { return }
        closing = true
        let retained = store.retainedAttachmentPaths
        Task { await attachmentModel?.finishCommit(retaining: retained); dismiss() }
    }

    private func binding<Value>(_ path: WritableKeyPath<Assignment, Value>) -> Binding<Value> {
        Binding(get: { editor.draft[keyPath: path] }, set: { editor.set(path, $0) })
    }

    private func optionalBinding(_ path: WritableKeyPath<Assignment, String?>) -> Binding<String> {
        Binding(get: { editor.draft[keyPath: path] ?? "" }, set: { editor.set(path, $0.isEmpty ? nil : $0) })
    }
}
