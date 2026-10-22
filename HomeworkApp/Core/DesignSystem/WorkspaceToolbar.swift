import SwiftUI
import Observation
import HomeworkDomain

enum WorkspaceToolbarMode: Equatable { case assignments, calendar }

@Observable @MainActor
final class WorkspaceToolbarModel {
    struct Request: Equatable {
        enum Action: Equatable { case add, ai, today }
        let id = UUID()
        let mode: WorkspaceToolbarMode
        let action: Action
    }
    var mode: WorkspaceToolbarMode = .assignments
    var selectedSection = "Assignments"
    var activation = 0
    var category: AssignmentFilter = .upcoming
    var sort: AssignmentSort = .priority
    var request: Request?
    func activate(_ section: String) {
        selectedSection = section
        if section == "Assignments" { mode = .assignments }
        if section == "Calendar" { mode = .calendar }
        activation += 1
    }
    func send(_ action: Request.Action, from mode: WorkspaceToolbarMode) {
        request = Request(mode: mode, action: action)
    }
}

private struct WorkspaceToolbarKey: EnvironmentKey {
    static let defaultValue: WorkspaceToolbarModel? = nil
}
extension EnvironmentValues {
    var workspaceToolbar: WorkspaceToolbarModel? {
        get { self[WorkspaceToolbarKey.self] }
        set { self[WorkspaceToolbarKey.self] = newValue }
    }
}

/// Real native items retain their glass, anchored menus, press effects and shared Add identity.
struct WorkspaceToolbar: ToolbarContent {
    @Bindable var model: WorkspaceToolbarModel
    let mode: WorkspaceToolbarMode

    var body: some ToolbarContent {
        ToolbarItem(id: "workspace.context", placement: .topBarTrailing) {
            Group {
                if mode == .assignments {
                    Menu {
                        Picker("Sort by", selection: $model.sort) {
                            ForEach(AssignmentSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: { Label("Sort", systemImage: "arrow.up.arrow.down") }
                    .accessibilityIdentifier("assignments.sort")
                } else {
                    Button("Today") { model.send(.today, from: mode) }
                        .accessibilityIdentifier("calendar.today")
                }
            }
            .modifier(WorkspaceActionTransition(model: model, mode: mode))
        }
        ToolbarItem(id: "workspace.add", placement: .topBarTrailing) {
            Button("Add assignment", systemImage: "plus") { model.send(.add, from: mode) }
                .accessibilityIdentifier(mode == .assignments ? "assignments.add" : "calendar.add")
                .modifier(WorkspaceActionTransition(model: model, mode: mode))
        }
        ToolbarItem(id: "workspace.ai", placement: .topBarTrailing) {
            if mode == .assignments {
                Button("Add with AI", systemImage: "sparkles") { model.send(.ai, from: mode) }
                    .accessibilityIdentifier("assignments.ai")
                    .modifier(WorkspaceActionTransition(model: model, mode: mode))
            }
        }
    }
}

private struct WorkspaceActionTransition: ViewModifier {
    let model: WorkspaceToolbarModel
    let mode: WorkspaceToolbarMode
    @Environment(\.appReduceMotion) private var reduceMotion
    @State private var appeared = false
    private var active: Bool { model.selectedSection == (mode == .assignments ? "Assignments" : "Calendar") }
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary).tint(.primary)
            .scaleEffect(reduceMotion || (active && appeared) ? 1 : 0.86)
            .opacity(active ? 1 : 0)
            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : model.activation)
            .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.68), value: active && appeared)
            .onAppear { appeared = true }
            .onDisappear { appeared = false }
    }
}
