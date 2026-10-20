import SwiftUI
import HomeworkDomain

struct AssignmentListView: View {
    let store: AssignmentStore
    let onOpen: (UUID) -> Void
    @State private var filter: AssignmentFilter = .upcoming
    @State private var sort: AssignmentSort = .priority
    @State private var adding = false
    @State private var addingAI = false
    @Environment(\.llmProviderFactory) private var providerFactory

    private var visible: [Assignment] { AssignmentQuery.apply(store.assignments, filter: filter, sort: sort) }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $filter) {
                ForEach(AssignmentFilter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal).padding(.vertical, 8)
            .accessibilityIdentifier("assignments.filter")
            List {
                ForEach(visible) { assignment in
                    HStack(alignment: .top, spacing: 12) {
                        Button { store.toggleCompletion(assignment.id) } label: {
                            Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2).padding(.vertical, 3)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(assignment.isCompleted ? "Mark incomplete" : "Complete assignment")
                        .accessibilityIdentifier("assignment.complete.\(assignment.id)")
                        Button { onOpen(assignment.id) } label: {
                            AssignmentRow(assignment: assignment)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("assignment.open.\(assignment.id)")
                    }
                    .padding(.vertical, 3)
                    .swipeActions {
                        Button("Delete", role: .destructive) { store.delete(assignment.id) }
                        Button(assignment.isCompleted ? "Restore" : "Complete") { store.toggleCompletion(assignment.id) }
                            .tint(.green)
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") { onOpen(assignment.id) }
                        Button(assignment.isCompleted ? "Restore" : "Complete", systemImage: "checkmark") {
                            store.toggleCompletion(assignment.id)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) { store.delete(assignment.id) }
                    }
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("assignments.list")
            .overlay {
                if visible.isEmpty {
                    ContentUnavailableView(filter == .completed ? "No completed assignments" : "No assignments yet",
                                           systemImage: "checklist",
                                           description: Text("Add coursework to keep track of your deadlines."))
                        .accessibilityIdentifier("assignments.empty")
                }
            }
        }
        .navigationTitle("Assignments")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sort) {
                        ForEach(AssignmentSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }
                .accessibilityIdentifier("assignments.sort")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add assignment", systemImage: "plus") { adding = true }
                    .accessibilityIdentifier("assignments.add")
                    .keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add with AI", systemImage: "sparkles") { addingAI = true }
                    .accessibilityIdentifier("assignments.ai")
            }
        }
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(), isNew: true, store: store) }
        }
        .sheet(isPresented: $addingAI) {
            if let providerFactory {
                NavigationStack { AIImportView(store: store, providerFactory: providerFactory) }
            }
        }
    }
}
