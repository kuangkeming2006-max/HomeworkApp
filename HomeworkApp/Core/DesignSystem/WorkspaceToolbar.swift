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
    var sort: AssignmentSort = .priority
    var request: Request?
    var switching = false
    func send(_ action: Request.Action) { request = Request(mode: mode, action: action) }
}

struct WorkspacePageFade: ViewModifier {
    @Environment(\.workspacePageVisible) private var visible
    func body(content: Content) -> some View {
        content.opacity(visible ? 1 : 0)
    }
}

private struct WorkspaceToolbarKey: EnvironmentKey {
    static let defaultValue: WorkspaceToolbarModel? = nil
}
private struct WorkspacePageVisibilityKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var workspaceToolbar: WorkspaceToolbarModel? {
        get { self[WorkspaceToolbarKey.self] }
        set { self[WorkspaceToolbarKey.self] = newValue }
    }
    var workspacePageVisible: Bool {
        get { self[WorkspacePageVisibilityKey.self] }
        set { self[WorkspacePageVisibilityKey.self] = newValue }
    }
}

/// Both workspace pages render the same action strip. It morphs on the outgoing
/// page before native tab containment swaps navigation controllers.
struct WorkspaceToolbar: View {
    @Bindable var model: WorkspaceToolbarModel
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 0) {
                if model.mode == .assignments {
                    Menu {
                        Picker("Sort by", selection: $model.sort) {
                            ForEach(AssignmentSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: { Image(systemName: "arrow.up.arrow.down").frame(width: 44, height: 44) }
                    .accessibilityLabel("Sort").accessibilityIdentifier("assignments.sort")
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                    Button("Today") { model.send(.today) }.padding(.horizontal, 12).frame(height: 44)
                        .accessibilityIdentifier("calendar.today")
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                Button("Add assignment", systemImage: "plus") { model.send(.add) }
                    .labelStyle(.iconOnly).frame(width: 44, height: 44)
                    .matchedGeometryEffect(id: "add", in: glass)
                    .accessibilityIdentifier(model.mode == .assignments ? "assignments.add" : "calendar.add")
                if model.mode == .assignments {
                    Button("Add with AI", systemImage: "sparkles") { model.send(.ai) }
                        .labelStyle(.iconOnly).frame(width: 44, height: 44)
                        .accessibilityIdentifier("assignments.ai")
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .font(.title3)
            .foregroundStyle(.tint)
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .glassEffect(.regular.interactive(), in: .capsule)
            .glassEffectID("workspace.actions", in: glass)
            .glassEffectTransition(.matchedGeometry)
        }
        .fixedSize(horizontal: true, vertical: false)
        .disabled(model.switching)
    }
}
