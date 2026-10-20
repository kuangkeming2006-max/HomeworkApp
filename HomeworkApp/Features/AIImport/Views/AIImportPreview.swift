import SwiftUI
import HomeworkDomain

struct AIImportPreview: View {
    @Bindable var model: AIImportViewModel
    let didSave: () -> Void

    var body: some View {
        Form {
            Section {
                Text("Check the title, deadline, priority and reminder for each assignment. Unclear dates require your confirmation.")
                    .foregroundStyle(.secondary)
            }
            ForEach(model.candidates.indices, id: \.self) { index in
                CandidateForm(candidate: $model.candidates[index], index: index)
            }
            if let message = model.message { Section { Text(message).foregroundStyle(.red) } }
        }
        .navigationTitle("Review assignments")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save selected") { if model.confirm() { didSave() } }
                    .disabled(!model.canConfirm).accessibilityIdentifier("ai.confirm")
            }
        }
    }
}

private struct CandidateForm: View {
    @Binding var candidate: ImportCandidate
    let index: Int

    var body: some View {
        Section {
            NativeToggleRow(title: "Import this assignment", isOn: $candidate.selected, identifier: "ai.select.\(index)")
            if candidate.selected {
                TextField("Title", text: $candidate.assignment.title).accessibilityIdentifier("ai.title.\(index)")
                TextField("Course", text: Binding(get: { candidate.assignment.course ?? "" }, set: { candidate.assignment.course = $0 }))
                DatePicker("Deadline", selection: $candidate.assignment.dueDate, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.timeZone, TimeZone(identifier: candidate.assignment.dueTimeZone) ?? .current)
                TextField("Time zone", text: $candidate.assignment.dueTimeZone).autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if candidate.requiresDateConfirmation {
                    Text(candidate.dateIssue ?? "Confirm this deadline.").foregroundStyle(.orange)
                    NativeToggleRow(title: "I confirmed this deadline", isOn: $candidate.dateConfirmed, identifier: "ai.confirmDate.\(index)")
                }
                Picker("Priority", selection: $candidate.assignment.priority) {
                    ForEach(Priority.allCases) { Text($0.label).tag($0) }
                }
                ReminderPicker(value: $candidate.assignment.reminder)
                if let notes = candidate.assignment.notes, !notes.isEmpty { Text(notes).foregroundStyle(.secondary) }
            }
        } header: { Text("Assignment \(index + 1)") }
    }
}
