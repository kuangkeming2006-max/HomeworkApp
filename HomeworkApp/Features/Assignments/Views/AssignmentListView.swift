import SwiftUI

struct AssignmentListView: View {
    var body: some View {
        ContentUnavailableView(
            "No assignments yet",
            systemImage: "checklist",
            description: Text("Keep track of your coursework and deadlines.")
        )
        .navigationTitle("Assignments")
        .accessibilityIdentifier("assignments.empty")
    }
}
