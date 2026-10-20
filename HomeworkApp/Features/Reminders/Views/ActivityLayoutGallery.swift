#if DEBUG
import SwiftUI

/// Simulator layout evidence using the extension's shared views, not a delivery simulator.
struct ActivityLayoutGallery: View {
    private let state = HomeworkActivityAttributes.ContentState(
        title: "Networking laboratory report", course: "Computer networks",
        deadline: .now.addingTimeInterval(3600), start: .now, priority: 1)
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Layout previews only. System presentation and delivery require a device.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Lock Screen").font(.headline)
                DeadlineActivityContent(state: state).padding().background(.black, in: RoundedRectangle(cornerRadius: 20))
                Text("Compact").font(.headline)
                HStack {
                    Image(systemName: "doc.badge.clock")
                    Spacer()
                    DeadlineCountdown(deadline: state.deadline).frame(width: 64)
                }.foregroundStyle(.white).padding().frame(maxWidth: 240).background(.black, in: Capsule())
                Text("Minimal").font(.headline)
                Image(systemName: "clock").foregroundStyle(.white).padding().background(.black, in: Circle())
                Text("Expanded content").font(.headline)
                DeadlineActivityContent(state: state).padding().background(.black, in: RoundedRectangle(cornerRadius: 32))
            }.padding().frame(maxWidth: 500).frame(maxWidth: .infinity)
        }.navigationTitle("Live Activity layouts")
    }
}
#endif
