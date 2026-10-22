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
        .preferredColorScheme(effectiveColorScheme)
        .environment(\.accessibilityReduceMotion, effectiveReduceMotion)
        .environment(\.dynamicTypeSize, effectiveTypeSize)
        .environment(\.attachmentService, container.attachmentService)
        .environment(\.llmProviderFactory, { [container] in try container.makeLLMProvider() })
        .onChange(of: scenePhase) { _, phase in
            container.setForeground(phase == .active)
        }
        .onChange(of: selection, initial: true) { _, section in
            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.75)) {
                workspaceToolbar.activate(section?.rawValue ?? "Assignments")
            }
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

    private var effectiveReduceMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--reduce-motion") { return true }
        #endif
        return reduceMotion
    }
    private var effectiveColorScheme: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--dark") { return .dark }
        #endif
        return container.preferences.appearance.colorScheme
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
                    } label: {
                        Label(section.rawValue, systemImage: section.symbol)
                            .accessibilityIdentifier(section.identifier)
                    }
                }
            }
            .tabBarMinimizeBehavior(.never)
            .modifier(UndoTabAccessory(coordinator: store.undo) {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.24)) { store.undoLatest() }
            })
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
        case .briefing: NavigationStack { BriefingView(store: store, history: container.briefingHistory) }
        case .settings: NavigationStack {
            SettingsView(version: container.version, preferences: container.preferences,
                         notifications: container.notifications, store: store, backupService: container.backupService,
                         secrets: container.secrets, buildProvider: container.providerBuilder, liveActivities: container.liveActivities)
        }
        }
      }
      // Each sidebar destination owns a different navigation path. Keep their identities
      // distinct so SwiftUI never compares a task UUID path with another column's path.
      .id(section)
    }

    private func open(_ route: HomeworkRoute) {
        switch route {
        case .assignment(let id): selection = .assignments; requestedAssignment = .init(assignmentID: id)
        case .briefing: selection = .briefing
        }
    }
}
