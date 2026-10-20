import SwiftUI
import Foundation

struct DeadlineActivityContent: View {
    let state: HomeworkActivityAttributes.ContentState
    var isStale = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Homework", systemImage: "doc.badge.clock").font(.caption.bold())
                Spacer(); Text("P\(state.priority) · \(isStale ? "Due now" : "Due soon")").font(.caption)
            }
            Text(state.title).font(.headline).lineLimit(2)
            HStack {
                Text(state.course ?? "Time to make progress").font(.subheadline).lineLimit(1)
                Spacer()
                DeadlineCountdown(deadline: state.deadline, isStale: isStale).font(.title2.monospacedDigit().bold())
            }
        }.foregroundStyle(.white)
    }
}

struct DeadlineCountdown: View {
    let deadline: Date
    var isStale = false
    var body: some View {
        if !isStale, deadline > Date() {
            Text(timerInterval: Date()...deadline, countsDown: true).monospacedDigit()
                .accessibilityLabel("Time until deadline")
        } else { Text("Due now") }
    }
}

