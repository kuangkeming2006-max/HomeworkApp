import SwiftUI
import Foundation

struct DeadlineActivityContent: View {
    let state: HomeworkActivityAttributes.ContentState
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Homework", systemImage: "doc.badge.clock").font(.caption.bold())
                Spacer(); Text("P\(state.priority) · Due soon").font(.caption)
            }
            Text(state.title).font(.headline).lineLimit(2)
            HStack {
                Text(state.course ?? "Time to make progress").font(.subheadline).lineLimit(1)
                Spacer()
                DeadlineCountdown(deadline: state.deadline).font(.title2.monospacedDigit().bold())
            }
        }.foregroundStyle(.white)
    }
}

struct DeadlineCountdown: View {
    let deadline: Date
    var body: some View {
        if deadline > Date() {
            Text(timerInterval: Date()...deadline, countsDown: true).monospacedDigit()
                .accessibilityLabel("Time until deadline")
        } else { Text("Due now") }
    }
}

