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
    @State private var category: AssignmentStatus = .active
    @State private var sectionHeaderPositions: [AssignmentStatus: CGFloat] = [:]
    @State private var listOriginY: CGFloat?
    @State private var listTopInset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.llmProviderFactory) private var providerFactory
    @Environment(\.attachmentService) private var attachmentService
    @Environment(\.workspaceToolbar) private var toolbar

    private struct ListScrollMetrics: Equatable {
        let collapsedTitle: Bool
        let topInset: CGFloat
    }

    var body: some View {
        ScrollViewReader { proxy in
          VStack(spacing: 0) {
            Picker("Category", selection: Binding(get: { category }, set: { next in
                category = next
                proxy.scrollTo(next, anchor: .top)
            })) {
                ForEach(AssignmentStatus.allCases) { Text($0.categoryTitle).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 8)
            .accessibilityIdentifier("assignments.filter")
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
                        HStack(spacing: 8) {
                            Circle().fill(section.id.markerColor).frame(width: 8, height: 8)
                            Text(section.title).font(.headline).foregroundStyle(.primary)
                        }
                            .textCase(nil).accessibilityIdentifier("assignments.section.\(section.id.rawValue)")
                            .onGeometryChange(for: CGFloat.self) { geometry in
                                geometry.frame(in: .global).minY.rounded(.down)
                            } action: { position in
                                guard sectionHeaderPositions[section.id] != position else { return }
                                sectionHeaderPositions[section.id] = position
                                updateCategoryForScroll()
                            }
                            .onDisappear {
                                if sectionHeaderPositions.removeValue(forKey: section.id) != nil { updateCategoryForScroll() }
                            }
                    }
                    .id(section.id)
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("assignments.list")
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.frame(in: .global).minY.rounded(.down)
            } action: { position in
                guard listOriginY != position else { return }
                listOriginY = position
                updateCategoryForScroll()
            }
            .onScrollGeometryChange(for: ListScrollMetrics.self) { geometry in
                ListScrollMetrics(collapsedTitle: geometry.contentOffset.y + geometry.contentInsets.top > 38,
                                  topInset: geometry.contentInsets.top)
            } action: { _, metrics in
                if collapsedTitle != metrics.collapsedTitle {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { collapsedTitle = metrics.collapsedTitle }
                }
                if listTopInset != metrics.topInset {
                    listTopInset = metrics.topInset
                    updateCategoryForScroll()
                }
            }
          }
          }
          .modifier(WorkspacePageFade())
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search title, course or notes")
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
            case .today: break
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if collapsedTitle { Text("Assignments").font(.headline).allowsHitTesting(false) }
            }
            .sharedBackgroundVisibility(.hidden)
            ToolbarItem(placement: .topBarTrailing) {
                if let toolbar { WorkspaceToolbar(model: toolbar) }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .fullScreenCover(item: $actionTarget) { AssignmentStatusSheet(assignment: $0, store: store) }
        .attachmentPreview(preview)
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(), isNew: true, store: store) }
        }
        .sheet(isPresented: $addingAI) {
            if let providerFactory { NavigationStack { AIImportView(store: store, providerFactory: providerFactory) } }
        }
    }

    private func updateCategoryForScroll() {
        guard let listOriginY else { return }
        let visibleTop = listOriginY + listTopInset
        let pastTop = AssignmentStatus.allCases.last { status in
            guard let position = sectionHeaderPositions[status] else { return false }
            return position <= visibleTop + 1
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
