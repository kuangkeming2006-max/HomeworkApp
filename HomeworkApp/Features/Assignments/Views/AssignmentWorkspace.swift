import SwiftUI

struct AssignmentNavigationRequest: Equatable {
    let id = UUID()
    let assignmentID: UUID
}

struct AssignmentWorkspace: View {
    let store: AssignmentStore
    var request: AssignmentNavigationRequest? = nil
    @State private var selectedID: UUID?
    @State private var path: [UUID] = []
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= 720 && !typeSize.isAccessibilitySize {
                HStack(spacing: 0) {
                    NavigationStack {
                        AssignmentListView(store: store) { selectedID = $0; path = [$0] }
                    }
                    .frame(width: min(380, geometry.size.width * 0.42))
                    Divider()
                    NavigationStack {
                        if let selectedID, let assignment = store.assignment(selectedID) {
                            AssignmentDetailView(assignment: assignment, store: store)
                                .id(selectedID)
                        } else {
                            ContentUnavailableView("Select an assignment", systemImage: "doc.text",
                                                   description: Text("Choose an assignment to see its details."))
                        }
                    }
                }
            } else {
                NavigationStack(path: $path) {
                    AssignmentListView(store: store) { selectedID = $0; path.append($0) }
                        .navigationDestination(for: UUID.self) { id in
                            if let assignment = store.assignment(id) {
                                AssignmentDetailView(assignment: assignment, store: store).id(id)
                            } else {
                                ContentUnavailableView("Assignment deleted", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .onChange(of: request, initial: true) { _, request in
            guard let id = request?.assignmentID else { return }
            selectedID = id
            path = [id]
        }
    }
}
