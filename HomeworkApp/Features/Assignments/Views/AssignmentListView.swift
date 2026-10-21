import SwiftUI
import HomeworkDomain

struct AssignmentListView: View {
    let store: AssignmentStore
    let onOpen: (UUID) -> Void
    @State private var sort: AssignmentSort = .priority
    @State private var adding = false
    @State private var addingAI = false
    @State private var choosingSort = false
    @State private var search = ""
    @State private var actionTarget: Assignment?
    @State private var projection = AssignmentListProjection()
    @State private var preview = AttachmentPreviewModel()
    @State private var category: AssignmentStatus = .active
    @State private var sectionHeaderPositions: [AssignmentStatus: CGFloat] = [:]
    @State private var listOriginY: CGFloat?
    @State private var listTopInset: CGFloat = 0
    @State private var requestedCategory: AssignmentStatus?
    @State private var hasUserScrolled = false
    @State private var atBottom = false
    @State private var atTop = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.llmProviderFactory) private var providerFactory
    @Environment(\.attachmentService) private var attachmentService
    @Environment(\.workspaceToolbar) private var toolbar

    private struct ListScrollMetrics: Equatable {
        let topInset: CGFloat
        let atTop: Bool
        let atBottom: Bool
    }

    var body: some View {
        ScrollViewReader { proxy in
            TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
            List {
                ForEach(projection.sections) { section in
                        HStack(spacing: 8) {
                            Circle().fill(section.id.markerColor).frame(width: 8, height: 8)
                            Text(section.title).font(.headline).foregroundStyle(.secondary)
                        }
                            .listRowInsets(EdgeInsets(top: 20, leading: 16, bottom: 12, trailing: 16))
                            .listRowSeparator(.hidden)
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("assignments.section.\(section.id.rawValue)")
                            .id(section.id)
                            .onGeometryChange(for: CGFloat.self) { geometry in
                                geometry.frame(in: .global).minY.rounded(.down)
                            } action: { position in
                                guard sectionHeaderPositions[section.id] != position else { return }
                                sectionHeaderPositions[section.id] = position
                                updateCategoryForScroll()
                            }
                            .onDisappear {
                                sectionHeaderPositions.removeValue(forKey: section.id)
                            }
                        if section.rows.isEmpty {
                            Text(search.isEmpty ? "No \(section.title.lowercased()) assignments" : "No matching assignments")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 14)
                                .accessibilityIdentifier("assignments.empty.\(section.id.rawValue)")
                        }
                        ForEach(section.rows) { assignment in
                            row(assignment, now: context.date)
                                .id(assignment.id)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                }
            }
            .listStyle(.plain)
            .contentMargins(.bottom, 16, for: .scrollContent)
            .accessibilityIdentifier("assignments.list")
            .safeAreaInset(edge: .top, spacing: 0) {
                categoryPicker(proxy: proxy)
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.frame(in: .global).minY.rounded(.down)
            } action: { position in
                guard listOriginY != position else { return }
                listOriginY = position
                updateCategoryForScroll()
            }
            .onScrollGeometryChange(for: ListScrollMetrics.self) { geometry in
                ListScrollMetrics(topInset: geometry.contentInsets.top,
                                  atTop: geometry.contentOffset.y + geometry.contentInsets.top <= 1,
                                  atBottom: geometry.contentOffset.y + geometry.containerSize.height
                                    >= geometry.contentSize.height + geometry.contentInsets.bottom - 1)
            } action: { _, metrics in
                atTop = metrics.atTop
                atBottom = metrics.atBottom
                if listTopInset != metrics.topInset {
                    listTopInset = metrics.topInset
                    updateCategoryForScroll()
                }
                if hasUserScrolled { updateCategoryForScroll() }
            }
            .onScrollPhaseChange { _, phase in
                // A category jump owns selection until the next deliberate scroll.
                // Intermediate header callbacks must not undo the user's choice.
                if phase == .interacting { hasUserScrolled = true; requestedCategory = nil }
                if phase == .idle, requestedCategory == nil { updateCategoryForScroll() }
            }
          }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search title, course or notes")
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
        .onChange(of: toolbar?.sort, initial: true) { _, value in if let value { sort = value } }
        .onChange(of: toolbar?.request) { _, request in
            guard let request, request.mode == .assignments else { return }
            switch request.action {
            case .add: adding = true
            case .ai: addingAI = true
            case .sort: choosingSort = true
            case .today: break
            }
        }
        .navigationTitle("Assignments")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let toolbar { WorkspaceToolbar(model: toolbar, mode: .assignments) }
        }
        .sheet(item: $actionTarget) { AssignmentStatusSheet(assignment: $0, store: store) }
        .confirmationDialog("Sort by", isPresented: $choosingSort, titleVisibility: .visible) {
            ForEach(AssignmentSort.allCases) { option in
                Button(option.rawValue) {
                    if let toolbar { toolbar.sort = option } else { sort = option }
                }
            }
        }
        .attachmentPreview(preview)
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(), isNew: true, store: store) }
        }
        .sheet(isPresented: $addingAI) {
            if let providerFactory { NavigationStack { AIImportView(store: store, providerFactory: providerFactory) } }
        }
    }

    private func categoryPicker(proxy: ScrollViewProxy) -> some View {
        Picker("Category", selection: Binding(get: { category }, set: { next in
            requestedCategory = next
            category = next
            // Native list scrolling clamps short terminal sections naturally.
            // No viewport-sized spacer is inserted below the actual content.
            // The separator is a concrete list row, so it is a reliable scroll
            // target and cannot pin over the first assignment's title.
            proxy.scrollTo(next, anchor: .top)
        })) {
            ForEach(AssignmentStatus.allCases) { Text($0.categoryTitle).tag($0) }
        }
        .accessibilityIdentifier("assignments.filter")
        .pickerStyle(.segmented).padding(.horizontal, 16).padding(.vertical, 8)
        .background(.bar, ignoresSafeAreaEdges: [])
    }

    private func updateCategoryForScroll() {
        guard requestedCategory == nil, let listOriginY else { return }
        if hasUserScrolled && atBottom && !atTop {
            if category != .abandoned { category = .abandoned }
            return
        }
        let visibleTop = listOriginY + listTopInset
        let pastTop = AssignmentStatus.allCases.last { status in
            guard let position = sectionHeaderPositions[status] else { return false }
            // Separator titles have a standard top row inset.
            return position <= visibleTop + 24
        }
        // Above the first header, the title area still belongs to Upcoming.
        let next = pastTop ?? (sectionHeaderPositions[.active] != nil ? AssignmentStatus.active : nil)
        if let next, category != next { category = next }
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
            }.tint(.red)
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
            Button("Delete", systemImage: "trash", role: .destructive) { change { store.delete(assignment.id) } }.tint(.red)
            if assignment.status == .active {
                Button("Abandon", systemImage: "minus.circle") { change { store.setStatus(assignment.id, to: .abandoned) } }
            }
        }
    }

    private func change(_ action: () -> Void) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28), action)
    }
}
