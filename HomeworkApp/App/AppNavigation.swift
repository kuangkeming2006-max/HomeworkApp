import SwiftUI
import UIKit
import HomeworkDomain

enum AppSection: String, CaseIterable, Identifiable {
    case assignments = "Assignments"
    case calendar = "Calendar"
    case briefing = "Briefing"
    case settings = "Settings"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .assignments: "checklist"
        case .calendar: "calendar"
        case .briefing: "chart.pie"
        case .settings: "gearshape"
        }
    }
    var identifier: String { "navigation.\(rawValue.lowercased())" }
}

struct AppNavigation: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var systemTypeSize
    @State private var selection: AppSection? = .assignments
    @State private var pageVisible = true
    @State private var pageTransition = UUID()
    @State private var workspaceToolbar = WorkspaceToolbarModel()
    @State private var requestedAssignment: AssignmentNavigationRequest?
    @State private var education = false
    let container: AppContainer

    var body: some View {
        Group {
            if let store = container.store {
                navigation(store: store)
                    .alert("Unable to save", isPresented: Binding(
                        get: { store.errorMessage != nil },
                        set: { if !$0 { store.errorMessage = nil } })) {
                            Button("OK", role: .cancel) { store.errorMessage = nil }
                        } message: { Text(store.errorMessage ?? "Please try again.") }
            } else {
                ContentUnavailableView {
                    Label("Unable to open your data", systemImage: "externaldrive.badge.exclamationmark")
                } description: { Text(container.startupError ?? "Please try reopening the app.") }
                  actions: { Button("Try again") { container.openStore() } }
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
        .tint(container.preferences.accent.color)
        .environment(\.appAccent, container.preferences.accent.color)
        .environment(\.workspaceToolbar, workspaceToolbar)
        .environment(\.workspacePageVisible, pageVisible)
        .preferredColorScheme(container.preferences.appearance.colorScheme)
        .environment(\.dynamicTypeSize, effectiveTypeSize)
        .environment(\.attachmentService, container.attachmentService)
        .environment(\.llmProviderFactory, { [container] in try container.makeLLMProvider() })
        .onChange(of: scenePhase) { _, phase in
            container.setForeground(phase == .active)
        }
        .onChange(of: selection) { _, section in
            if let mode = toolbarMode(section), !workspaceToolbar.switching { workspaceToolbar.mode = mode }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            container.refreshServices()
        }
        .onOpenURL { url in if let route = HomeworkRoute(url: url) { open(route) } }
        .onChange(of: container.pendingRoute, initial: true) { _, route in
            if let route { open(route); container.pendingRoute = nil }
        }
        .task {
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            education = !container.preferences.notificationEducationSeen && !testing
            #if DEBUG
            if testing, ProcessInfo.processInfo.arguments.contains("--show-onboarding") { education = true }
            #endif
        }
        .sheet(isPresented: $education, onDismiss: { container.preferences.notificationEducationSeen = true }) {
            NotificationEducationView(enable: { await container.notifications.enable() }, finish: {
                container.preferences.notificationEducationSeen = true; education = false
            })
        }
    }

    private var effectiveTypeSize: DynamicTypeSize {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitesting"), args.contains("--large-type") { return .accessibility3 }
        #endif
        return systemTypeSize
    }

    @ViewBuilder
    private func navigation(store: AssignmentStore) -> some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(AppSection.allCases, selection: $selection) { section in
                    Label(section.rawValue, systemImage: section.symbol)
                        .tag(section)
                        .accessibilityIdentifier(section.identifier)
                }
                .navigationTitle("Homework")
            } detail: {
                destination(selection ?? .assignments, store: store)
            }
            .safeAreaInset(edge: .bottom) { snackbar(store) }
        } else {
            TabView(selection: $selection) {
                ForEach(AppSection.allCases) { section in
                    Tab(value: Optional(section)) {
                        destination(section, store: store)
                            .toolbar(.hidden, for: .tabBar)
                    } label: { Label(section.rawValue, systemImage: section.symbol) }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .allowsHitTesting(pageVisible)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                equalWidthTabBar.overlay(alignment: .bottom) {
                    snackbar(store).padding(.bottom, 70)
                }
            }
        }
    }

    private var equalWidthTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppSection.allCases) { section in
                Button {
                    selectSection(section)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.symbol).font(.system(size: 21, weight: .semibold))
                        Text(section.rawValue).font(.caption2.weight(.semibold))
                            .lineLimit(1).minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(selection == section ? container.preferences.accent.color : Color.secondary)
                    .background {
                        if selection == section {
                            Capsule().fill(Color.primary.opacity(0.08)).padding(3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(section.identifier)
                .accessibilityAddTraits(selection == section ? [.isSelected] : [])
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16).padding(.bottom, 4)
        .accessibilityElement(children: .contain)
    }

    private func selectSection(_ section: AppSection) {
        guard selection != section || !pageVisible else { return }
        AppHaptics.selection()
        let token = UUID()
        pageTransition = token
        guard !reduceMotion else {
            if let mode = toolbarMode(section) { workspaceToolbar.mode = mode }
            selection = section; pageVisible = true; workspaceToolbar.switching = false; return
        }
        let morphsToolbar = toolbarMode(selection) != nil && toolbarMode(section) != nil
        workspaceToolbar.switching = true
        withAnimation(morphsToolbar ? .spring(response: 0.3, dampingFraction: 0.72) : .easeInOut(duration: 0.18), completionCriteria: .logicallyComplete) {
            if let mode = toolbarMode(section) { workspaceToolbar.mode = mode }
            pageVisible = false
        } completion: {
            guard pageTransition == token else { return }
            selection = section
            workspaceToolbar.switching = false
            pageVisible = true
        }
    }

    private func toolbarMode(_ section: AppSection?) -> WorkspaceToolbarMode? {
        switch section {
        case .assignments: .assignments
        case .calendar: .calendar
        default: nil
        }
    }

    private func snackbar(_ store: AssignmentStore) -> some View {
        UndoSnackbar(coordinator: store.undo) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.28)) { store.undoLatest() }
        }
    }

    @ViewBuilder
    private func destination(_ section: AppSection, store: AssignmentStore) -> some View {
      Group {
        switch section {
        case .assignments: AssignmentWorkspace(store: store, request: requestedAssignment)
        case .calendar: NavigationStack { CalendarView(store: store) }
        case .briefing: NavigationStack { BriefingView(store: store, history: container.briefingHistory).modifier(WorkspacePageFade()) }
        case .settings: NavigationStack {
            SettingsView(version: container.version, preferences: container.preferences,
                         notifications: container.notifications, store: store, backupService: container.backupService,
                         secrets: container.secrets, buildProvider: container.providerBuilder, liveActivities: container.liveActivities)
                .modifier(WorkspacePageFade())
        }
        }
      }
      // Each sidebar destination owns a different navigation path. Keep their identities
      // distinct so SwiftUI never compares a task UUID path with another column's path.
      .id(section)
    }

    private func open(_ route: HomeworkRoute) {
        pageTransition = UUID()
        pageVisible = true
        workspaceToolbar.switching = false
        switch route {
        case .assignment(let id): selection = .assignments; requestedAssignment = .init(assignmentID: id)
        case .briefing: selection = .briefing
        }
        if let mode = toolbarMode(selection) { workspaceToolbar.mode = mode }
    }
}
