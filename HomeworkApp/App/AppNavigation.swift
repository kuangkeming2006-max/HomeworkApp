import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case assignments = "Assignments"
    case calendar = "Calendar"
    case settings = "Settings"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .assignments: "checklist"
        case .calendar: "calendar"
        case .settings: "gearshape"
        }
    }
    var identifier: String { "navigation.\(rawValue.lowercased())" }
}

struct AppNavigation: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: AppSection? = .assignments
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
        } else {
            TabView {
                ForEach(AppSection.allCases) { section in
                    Tab {
                        destination(section, store: store)
                    } label: {
                        Label(section.rawValue, systemImage: section.symbol)
                            .accessibilityIdentifier(section.identifier)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(_ section: AppSection, store: AssignmentStore) -> some View {
        switch section {
        case .assignments: AssignmentWorkspace(store: store)
        case .calendar: NavigationStack { CalendarView(store: store) }
        case .settings: NavigationStack { SettingsView(version: container.version) }
        }
    }
}
