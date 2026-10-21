import SwiftUI
import Observation
import HomeworkDomain

enum WorkspaceToolbarMode: Equatable { case assignments, calendar }

@Observable @MainActor
final class WorkspaceToolbarModel {
    struct Request: Equatable {
        enum Action: Equatable { case add, ai, today, sort }
        let id = UUID()
        let mode: WorkspaceToolbarMode
        let action: Action
    }
    var mode: WorkspaceToolbarMode = .assignments
    var sort: AssignmentSort = .priority
    var request: Request?
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

/// Native toolbar items own their glass, hit targets and press animation.
/// Page selection never waits for a toolbar animation to finish.
struct WorkspaceToolbar: ToolbarContent {
    @Bindable var model: WorkspaceToolbarModel
    let mode: WorkspaceToolbarMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if mode == .assignments {
                Button("Sort", systemImage: "arrow.up.arrow.down") { model.send(.sort, from: mode) }
                    .accessibilityIdentifier("assignments.sort")
            } else {
                Button("Today") { model.send(.today, from: mode) }
                    .accessibilityIdentifier("calendar.today")
            }
            Button("Add assignment", systemImage: "plus") { model.send(.add, from: mode) }
                .accessibilityIdentifier(mode == .assignments ? "assignments.add" : "calendar.add")
                .symbolEffect(.bounce, value: reduceMotion ? WorkspaceToolbarMode.assignments : model.mode)
            if mode == .assignments {
                Button("Add with AI", systemImage: "sparkles") { model.send(.ai, from: mode) }
                    .accessibilityIdentifier("assignments.ai")
            }
        }
    }
}
