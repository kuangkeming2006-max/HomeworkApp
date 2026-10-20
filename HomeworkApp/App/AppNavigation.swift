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
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(AppSection.allCases, selection: $selection) { section in
                    Label(section.rawValue, systemImage: section.symbol)
                        .tag(section)
                        .accessibilityIdentifier(section.identifier)
                }
                .navigationTitle("Homework")
            } detail: {
                NavigationStack { destination(selection ?? .assignments) }
            }
        } else {
            TabView {
                ForEach(AppSection.allCases) { section in
                    Tab {
                        NavigationStack { destination(section) }
                    } label: {
                        Label(section.rawValue, systemImage: section.symbol)
                            .accessibilityIdentifier(section.identifier)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(_ section: AppSection) -> some View {
        switch section {
        case .assignments: AssignmentListView()
        case .calendar: CalendarView()
        case .settings: SettingsView(version: container.version)
        }
    }
}
