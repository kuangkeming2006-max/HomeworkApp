import SwiftUI
import HomeworkDomain

struct AssignmentListView: View {
    let store: AssignmentStore
    let onOpen: (UUID) -> Void
    @State private var filter: AssignmentFilter = .upcoming
    @State private var sort: AssignmentSort = .priority
    @State private var adding = false
    @State private var addingAI = false
    @State private var search = ""
    @State private var actionTarget: Assignment?
    @State private var statusDialog = false
    @State private var projection = AssignmentListProjection()
    @State private var pageDirection = 1
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.llmProviderFactory) private var providerFactory

    private var visible: [Assignment] { projection.rows }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if sizeClass == .regular || typeSize.isAccessibilitySize {
                    categoryPicker.pickerStyle(.menu)
                } else { categoryPicker.pickerStyle(.segmented) }
            }
            .padding(.horizontal).padding(.vertical, 8)
            .accessibilityIdentifier("assignments.filter")
            .contentShape(Rectangle())
            .gesture(categorySwipe)
            TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
              List {
                ForEach(visible) { assignment in
                    HStack(alignment: .center, spacing: 12) {
                        Button { actionTarget = assignment; statusDialog = true } label: {
                            Image(systemName: assignment.status == .abandoned ? "minus.circle.fill" :
                                  assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2).frame(minWidth: 32, minHeight: 44)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Change assignment status").accessibilityValue(assignment.status.label)
                        .accessibilityIdentifier("assignment.complete.\(assignment.id)")
                        Button { onOpen(assignment.id) } label: {
                            AssignmentRow(assignment: assignment, now: context.date)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("assignment.open.\(assignment.id)")
                    }
                    .padding(.vertical, 3)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button { store.toggleCompletion(assignment.id) } label: {
                            Label(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark")
                        }.tint(.green)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { store.delete(assignment.id) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        if assignment.status == .active {
                            Button { store.setStatus(assignment.id, to: .abandoned) } label: {
                                Label("Abandon", systemImage: "minus.circle")
                            }.tint(.gray)
                        }
                    }
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") { onOpen(assignment.id) }
                        Button(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark") {
                            store.toggleCompletion(assignment.id)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) { store.delete(assignment.id) }
                        if assignment.status == .active {
                            Button("Abandon", systemImage: "minus.circle") { store.setStatus(assignment.id, to: .abandoned) }
                        }
                    }
                }
              }
            .listStyle(.plain)
            .accessibilityIdentifier("assignments.list")
            .overlay {
                if visible.isEmpty {
                    ContentUnavailableView(emptyTitle,
                                           systemImage: "checklist",
                                           description: Text("Add coursework to keep track of your deadlines."))
                        .accessibilityIdentifier("assignments.empty")
                        .contentShape(Rectangle()).gesture(categorySwipe)
                }
            }
            .id(filter)
            .transition(.asymmetric(insertion: .move(edge: pageDirection > 0 ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: pageDirection > 0 ? .leading : .trailing).combined(with: .opacity)))
            }
            .clipped()
        }
        .searchable(text: $search, prompt: "Search title, course or notes")
        .onChange(of: store.assignments, initial: true) { _, values in projection.rebuild(values, sort: sort, filter: filter, search: search) }
        .onChange(of: sort) { _, _ in projection.rebuild(store.assignments, sort: sort, filter: filter, search: search) }
        .onChange(of: search) { _, _ in projection.refilter(filter, search: search) }
        .onChange(of: filter) { previous, next in
            let cases = AssignmentFilter.allCases
            pageDirection = (cases.firstIndex(of: next) ?? 0) >= (cases.firstIndex(of: previous) ?? 0) ? 1 : -1
            projection.refilter(filter, search: search)
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.22), value: filter)
        .confirmationDialog("Assignment status", isPresented: $statusDialog,
                            titleVisibility: .visible, presenting: actionTarget) { target in
                if target.status == .active {
                    Button("Complete") { store.setStatus(target.id, to: .completed) }
                    Button("Abandon") { store.setStatus(target.id, to: .abandoned) }
                } else {
                    Button("Restore") { store.setStatus(target.id, to: .active) }
                }
                Button("Cancel", role: .cancel) {}
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

    private var categoryPicker: some View {
        Picker("Category", selection: $filter) {
            ForEach(AssignmentFilter.allCases) { Text($0.rawValue).tag($0) }
        }
    }

    private var emptyTitle: String {
        if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "No matching assignments" }
        switch filter {
        case .completed: return "No completed assignments"
        case .abandoned: return "No abandoned assignments"
        case .upcoming, .all: return "No assignments yet"
        }
    }

    // Paging belongs to the category header and empty area. Native list rows own their swipes.
    private var categorySwipe: some Gesture {
        DragGesture(minimumDistance: 28).onEnded { value in
            guard sizeClass == .compact, abs(value.translation.width) > abs(value.translation.height) * 1.5,
                  abs(value.predictedEndTranslation.width) > 60,
                  let index = AssignmentFilter.allCases.firstIndex(of: filter) else { return }
            let next = index + (value.translation.width < 0 ? 1 : -1)
            if AssignmentFilter.allCases.indices.contains(next) { filter = AssignmentFilter.allCases[next] }
        }
    }
}
