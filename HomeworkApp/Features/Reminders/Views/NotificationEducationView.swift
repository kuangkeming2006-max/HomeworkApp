import SwiftUI

struct NotificationEducationView: View {
    let enable: () async -> Void
    let finish: () -> Void
    @State private var requesting = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "bell.badge").font(.system(size: 48)).foregroundStyle(.tint).accessibilityHidden(true)
            Text("A little nudge before it's due").font(.largeTitle.bold())
            Text("Choose a reminder for each assignment. Homework can notify you before a deadline and send an optional daily briefing.")
                .font(.body).foregroundStyle(.secondary)
            Text("Your assignments work offline even when notifications are disabled.").font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Button {
                requesting = true
                Task { await enable(); requesting = false; finish() }
            } label: {
                HStack { Spacer(); if requesting { ProgressView() }; Text("Enable notifications"); Spacer() }
            }.buttonStyle(.borderedProminent).disabled(requesting).accessibilityIdentifier("onboarding.enable")
            Button("Not now", action: finish).frame(maxWidth: .infinity).disabled(requesting)
                .accessibilityIdentifier("onboarding.skip")
        }.padding(28).presentationDetents([.large]).interactiveDismissDisabled(requesting)
    }
}
