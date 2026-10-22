import SwiftUI
import HomeworkDomain

struct AssignmentListView: View {
    let store: AssignmentStore
    let onOpen: (UUID) -> Void
    @State private var sort: AssignmentSort = .priority
    @State private var fallbackCategory: AssignmentFilter = .upcoming
    @State private var adding = false
    @State private var addingAI = false
    @State private var search = ""
    @State private var searchExpanded = false
    @State private var scrollInteraction = AssignmentScrollInteraction()
    @State private var projection = AssignmentListProjection()
    @State private var preview = AttachmentPreviewModel()
    @State private var visibleIDs: Set<UUID> = []
    @State private var headingLayout = AssignmentHeadingLayout()
    @Environment(\.appReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var titleTypeSize
    @Environment(\.llmProviderFactory) private var providerFactory
    @Environment(\.attachmentService) private var attachmentService
    @Environment(\.workspaceToolbar) private var toolbar

    private var category: AssignmentFilter { toolbar?.category ?? fallbackCategory }
    private var motion: Animation? { reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.86) }

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
          GeometryReader { viewport in
            let visibleTop = max(viewport.frame(in: .global).minY, viewport.safeAreaInsets.top)
            List {
              Section {
                assignmentHeading(large: true)
                    .id("assignments.heading.row")
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowSeparatorTint(.clear)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { _, frame in
                        headingLayout.update(headerBottom: frame.maxY, visibleTop: visibleTop)
                        if !searchExpanded, scrollInteraction.isUserScrolling, frame.minY > visibleTop + 40 {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { searchExpanded = true }
                        } else if searchExpanded, search.isEmpty, frame.maxY < visibleTop {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { searchExpanded = false }
                        }
                    }
                    .background(AssignmentScrollProbe(interaction: scrollInteraction).frame(width: 0, height: 0))
                if searchExpanded {
                    AssignmentSearchField(text: $search) {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { searchExpanded = false }
                    }
                    .frame(height: 56)
                    .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    .listRowSeparator(.hidden).listRowSeparatorTint(.clear)
                }
              }
              .listSectionSeparator(.hidden)
              Section {
                ForEach(projection.entries) { entry in
                    switch entry {
                    case .heading(let status):
                        HStack(spacing: 8) {
                            Circle().fill(status.markerColor).frame(width: 8, height: 8)
                            Text(status.categoryTitle).font(.headline).foregroundStyle(.secondary)
                        }
                        .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("assignments.section.\(status.rawValue)")
                    case .assignment(let assignment):
                        row(assignment, now: context.date)
                            .transition(rowTransition)
                            .onScrollVisibilityChange(threshold: 0.01) { visible in
                                if visible { visibleIDs.insert(assignment.id) } else { visibleIDs.remove(assignment.id) }
                            }
                    }
                }
              }
              .listSectionSeparator(.hidden, edges: .top)
            }
            .listStyle(.plain).contentMargins(.bottom, 16, for: .scrollContent)
            .contentMargins(.top, 0, for: .scrollContent)
            .listSectionSpacing(0)
            .scrollBounceBehavior(.always, axes: .vertical)
            .accessibilityIdentifier("assignments.list")
            .overlay {
                if projection.isEmpty {
                    ContentUnavailableView(emptyTitle, systemImage: category == .deleted ? "trash" : "checklist",
                                           description: Text(search.isEmpty ? emptyDescription : "Try another title, course or note."))
                        .accessibilityIdentifier("assignments.empty")
                        .allowsHitTesting(false)
                }
            }
          }
        }
        .onChange(of: store.assignments, initial: true) { _, _ in rebuild(animated: true) }
        .onChange(of: category) { _, _ in rebuild(animated: true) }
        .onChange(of: sort) { _, _ in rebuild(animated: true) }
        .onChange(of: search) { _, _ in projection.refilter(filter: category, search: search) }
        .onChange(of: toolbar?.sort, initial: true) { _, value in if let value { sort = value } }
        .onChange(of: toolbar?.selectedSection) { _, section in
            if section != "Assignments" { projection.clearPending(); rebuild(animated: false) }
        }
        .task(id: projection.nextExpiry) {
            guard let date = projection.nextExpiry else { return }
            do { try await Task.sleep(for: .seconds(max(0, date.timeIntervalSinceNow))) } catch { return }
            guard !Task.isCancelled else { return }
            let expired = projection.expire()
            rebuild(animated: !expired.isDisjoint(with: visibleIDs))
        }
        .onChange(of: toolbar?.request) { _, request in
            guard let request, request.mode == .assignments else { return }
            switch request.action {
            case .add: adding = true
            case .ai: addingAI = true
            case .today: break
            }
        }
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Keep the semantic Back label. The large heading scrolls as real content;
            // the fixed native bar receives ordinary leading text once it has left.
            ToolbarItem(placement: .principal) {
                Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
            }
            ToolbarItem(placement: .topBarLeading) {
                if headingLayout.isCompact { assignmentHeading(large: false) }
            }
            .sharedBackgroundVisibility(.hidden)
            if let toolbar { WorkspaceToolbar(model: toolbar, mode: .assignments) }
        }
        .attachmentPreview(preview)
        .navigationDestination(isPresented: $adding) {
            AssignmentDetailView(assignment: store.makeDraft(), isNew: true, store: store)
        }
        .sheet(isPresented: $addingAI) {
            if let providerFactory { NavigationStack { AIImportView(store: store, providerFactory: providerFactory) } }
        }
    }

    private func assignmentHeading(large: Bool) -> some View {
        HStack(alignment: .center, spacing: large ? 12 : 6) {
            Text("Assignments")
                .font(large ? .largeTitle.bold() : .headline)
                .foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(large ? "assignments.heading.large" : "assignments.heading.compact")
            if large { Spacer(minLength: 8) }
            Menu {
                Picker("Category", selection: Binding(get: { category }, set: {
                    if let toolbar { toolbar.category = $0 } else { fallbackCategory = $0 }
                })) {
                    ForEach(AssignmentFilter.allCases) { Text($0.rawValue).tag($0) }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(category.rawValue).lineLimit(1).minimumScaleFactor(0.65)
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                }
                .font(large ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                .foregroundStyle(.tint).frame(minHeight: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityIdentifier("assignments.filter")
            .accessibilityLabel("Category").accessibilityValue(category.rawValue)
        }
        .frame(maxWidth: large ? .infinity : nil, alignment: .leading)
        .fixedSize(horizontal: !large, vertical: false)
        .dynamicTypeSize(large ? titleTypeSize : min(titleTypeSize, .large))
        .accessibilityElement(children: .contain)
        .accessibilityHidden(false)
    }

    private var rowTransition: AnyTransition {
        reduceMotion ? .opacity : AnyTransition(BlurReplaceTransition(configuration: .downUp))
    }

    private var emptyTitle: String {
        if !search.isEmpty { return "No matching assignments" }
        switch category {
        case .all: return "No assignments yet"
        case .upcoming: return "You're all caught up"
        case .completed: return "No completed assignments"
        case .abandoned: return "No abandoned assignments"
        case .deleted: return "No deleted assignments"
        }
    }
    private var emptyDescription: String {
        switch category {
        case .deleted: "Deleted assignments stay here until you restore them."
        case .completed: "Assignments you complete will appear here."
        case .abandoned: "Assignments you abandon will appear here."
        default: "Add coursework to keep track of your deadlines."
        }
    }

    private func row(_ assignment: Assignment, now: Date) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if assignment.deletedAt != nil {
                Button("Restore deleted assignment", systemImage: "arrow.uturn.backward.circle") {
                    change { store.restoreDeleted(assignment.id) }
                }
                .labelStyle(.iconOnly).font(.title2).buttonStyle(.borderless)
                .frame(minWidth: 32, minHeight: 44).accessibilityIdentifier("assignment.recover.\(assignment.id)")
            } else {
                AssignmentCompletionButton(assignment: assignment) { toggle(assignment) }
                    .accessibilityIdentifier("assignment.complete.\(assignment.id)")
            }
            AssignmentRow(assignment: assignment, now: now, onOpen: {
                if assignment.deletedAt == nil { onOpen(assignment.id) }
            }, onPreview: { reference in Task { await preview.open(reference, service: attachmentService) } })
        }
        .padding(.vertical, 3).listRowSeparator(.visible, edges: .bottom)
        .listRowSeparator(.hidden, edges: .top)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if assignment.deletedAt != nil {
                Button("Restore", systemImage: "arrow.uturn.backward") { change { store.restoreDeleted(assignment.id) } }.tint(.green)
            } else {
                Button(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark") { toggle(assignment) }.tint(.green)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if assignment.deletedAt == nil {
                Button("Delete", systemImage: "trash", role: .destructive) { change { store.delete(assignment.id) } }.tint(.red)
                if assignment.status == .active {
                    Button("Abandon", systemImage: "minus.circle") { change { store.setStatus(assignment.id, to: .abandoned) } }.tint(.gray)
                }
            }
        }
        .contextMenu {
            if assignment.deletedAt != nil {
                Button("Restore", systemImage: "arrow.uturn.backward") { change { store.restoreDeleted(assignment.id) } }
            } else {
                Button("Edit", systemImage: "pencil") { onOpen(assignment.id) }
                Button(assignment.status == .active ? "Complete" : "Restore", systemImage: "checkmark") { toggle(assignment) }
                Button("Delete", systemImage: "trash", role: .destructive) { change { store.delete(assignment.id) } }.tint(.red)
                if assignment.status == .active {
                    Button("Abandon", systemImage: "minus.circle") { change { store.setStatus(assignment.id, to: .abandoned) } }
                }
            }
        }
    }

    private func toggle(_ assignment: Assignment) {
        if category == .upcoming, assignment.status == .active { projection.keepCompleted(assignment.id) }
        change { store.toggleCompletion(assignment.id) }
    }
    private func change(_ action: () -> Void) { withAnimation(motion, action) }
    private func rebuild(animated: Bool) {
        withAnimation(animated ? motion : nil) {
            projection.rebuild(store.assignments, sort: sort, filter: category, search: search)
        }
    }
}
