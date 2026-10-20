import SwiftUI

struct CalendarView: View {
    var body: some View {
        ContentUnavailableView(
            "Your deadlines, together",
            systemImage: "calendar",
            description: Text("Assignments will appear here when you add them.")
        )
        .navigationTitle("Calendar")
        .accessibilityIdentifier("calendar.empty")
    }
}
