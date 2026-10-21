import SwiftUI
import HomeworkDomain

struct AssignmentListView: View {
    let store: AssignmentStore
    let onOpen: (UUID) -> Void
    @State private var sort: AssignmentSort = .priority
    @State private var adding = false
    @State private var addingAI = false
    @State private var search = ""
    @State private var actionTarget: Assignment?
    @State private var projection = AssignmentListProjection()
    @State private var collapsedTitle = false
    @State private var preview = AttachmentPreviewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.llmProviderFactory) private var providerFactory
    @Environment(\.attachmentService) private var attachmentService

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
            List {
                Text("Assignments").font(.largeTitle.bold())
                    .listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .accessibilityAddTraits(.isHeader)
                ForEach(projection.sections) { section in
                    Section {
                        if section.rows.isEmpty {
                            Text(search.isEmpty ? "No \(section.title.lowercased()) assignments" : "No matching assignments")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 14)
                                .accessibilityIdentifier("assignments.empty.\(section.id.rawValue)")
                        }
                        ForEach(section.rows) { assignment in
                            row(assignment, now: context.date)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    } header: {
                        Text(section.title).font(.headline).foregroundStyle(.primary)
                            .textCase(nil).accessibilityIdentifier("assignments.section.\(section.id.rawValue)")
                    }
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("assignments.list")
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 38
            } action: { _, collapsed in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { collapsedTitle = collapsed }
            }
        }
        .searchable(text: $search, prompt: "Search title, course or notes")
        .onChange(of: store.assignments, initial: true) { _, values in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) {
                projection.rebuild(values, sort: sort, search: search)
            }
        }
        .onChange(of: sort) { _, _ in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.24)) {
                projection.rebuild(store.assignments, sort: sort, search: search)
            }
        }
        .onChange(of: search) { _, _ in projection.refilter(search: search) }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("Assignments").font(.headline).opacity(collapsedTitle ? 1 : 0)
                    .accessibilityHidden(!collapsedTitle)
            }
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
                    .accessibilityIdentifier("assignments.add").keyboardShortcut("n", modifiers: .command)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add with AI", systemImage: "sparkles") { addingAI = true }
                    .accessibilityIdentifier("assignments.ai")
            }
        }
        .sheet(item: $actionTarget) { AssignmentStatusSheet(assignment: $0, store: store) }
        .attachmentPreview(preview)
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(), isNew: true, store: store) }
        }
        .sheet(isPresented: $addingAI) {
            if let providerFactory { NavigationStack { AIImportView(store: store, providerFactory: providerFactory) } }
        }
    }

    private func row(_ assignment: Assignment, now: Date) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                AppHaptics.selection()
                actionTarget = assignment
            } label: {
                Image(systemName: assignment.status == .abandoned ? "minus.circle.fill" :
                      assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).frame(minWidth: 32, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Change assignment status").accessibilityValue(assignment.status.label)
            .accessibilityIdentifier("assignment.complete.\(assignment.id)")
            AssignmentRow(assignment: assignment, now: now, onOpen: { onOpen(assignment.id) }, onPreview: { reference in
                Task { await preview.open(reference, service: attachmentService) }
            })
        }
        .padding(.vertical, 3)
        .listRowSeparator(.visible, edges: .bottom)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .alignmentGuide(.listRowSeparatorTrailing) { dimensions in dimensions.width }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { change { store.toggleCompletion(assignment.id) } } label: {
                Label(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark")
            }.tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { change { store.delete(assignment.id) } } label: {
                Label("Delete", systemImage: "trash")
            }
            if assignment.status == .active {
                Button { change { store.setStatus(assignment.id, to: .abandoned) } } label: {
                    Label("Abandon", systemImage: "minus.circle")
                }.tint(.gray)
            }
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { onOpen(assignment.id) }
            Button(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark") {
                change { store.toggleCompletion(assignment.id) }
            }
            Button("Delete", systemImage: "trash", role: .destructive) { change { store.delete(assignment.id) } }
            if assignment.status == .active {
                Button("Abandon", systemImage: "minus.circle") { change { store.setStatus(assignment.id, to: .abandoned) } }
            }
        }
    }

    private func change(_ action: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28), action)
    }
}
