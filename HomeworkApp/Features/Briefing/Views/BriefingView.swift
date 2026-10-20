import SwiftUI
import HomeworkDomain

struct BriefingView: View {
    let store: AssignmentStore
    let history: BriefingHistoryStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let report = BriefingService.report(store.assignments, now: context.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack(spacing: 24) {
                        ZStack {
                            Circle().stroke(.quaternary, lineWidth: 9)
                            Circle().trim(from: 0, to: report.progress).stroke(.tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(report.completedDueToday)/\(report.dueToday)").font(.title2.bold().monospacedDigit()).minimumScaleFactor(0.6)
                        }.frame(width: 96, height: 96).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Today's deadlines").font(.headline)
                            Text(report.dueToday == 0 ? "No deadlines today" : "\(report.completedDueToday) of \(report.dueToday) completed")
                                .font(.title3.weight(.medium))
                            Text("Assignments due today, excluding abandoned work.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityElement(children: .combine).accessibilityIdentifier("briefing.progress")
                    Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 20) {
                        GridRow {
                            statistic("Remaining", value: report.remaining, symbol: "checklist", color: .primary)
                            statistic("Completed today", value: report.completedToday, symbol: "checkmark.circle", color: .green)
                        }
                        GridRow {
                            statistic("Due within 24 hours", value: report.dueWithin24Hours, symbol: "clock", color: .primary)
                            statistic("Overdue", value: report.overdue, symbol: "exclamationmark.circle", color: report.overdue > 0 ? .red : .secondary)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    if let urgent = report.mostUrgent, let task = store.assignment(urgent.id) {
                        Text("Next priority").font(.headline)
                        NavigationLink {
                            AssignmentDetailView(assignment: task, store: store)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(urgent.title).font(.title3.weight(.semibold)).foregroundStyle(.primary)
                                if let course = urgent.course { Text(course).font(.subheadline).foregroundStyle(.secondary) }
                                Text(timerInterval: context.date...max(context.date, urgent.deadline), countsDown: true)
                                    .font(.title.monospacedDigit().weight(.medium)).foregroundStyle(.primary)
                                Text(urgent.deadline, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain).accessibilityIdentifier("briefing.next")
                    } else {
                        ContentUnavailableView("A little room to breathe", systemImage: "checkmark.circle", description: Text("No upcoming deadlines right now."))
                    }
                    if !history.reports.isEmpty {
                        Divider()
                        NavigationLink("Previous reports") { BriefingHistoryView(history: history) }
                            .accessibilityIdentifier("briefing.history")
                    }
                }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
            }
            .onChange(of: context.date, initial: true) { _, _ in history.record(report) }
            .onChange(of: store.assignments) { _, _ in history.record(BriefingService.report(store.assignments, now: .now)) }
        }
        .navigationTitle("Briefing").accessibilityIdentifier("briefing.page")
    }

    private func statistic(_ label: String, value: Int, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)").font(.largeTitle.weight(.semibold).monospacedDigit()).foregroundStyle(color)
            Label(label, systemImage: symbol).font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }
}

private struct BriefingHistoryView: View {
    let history: BriefingHistoryStore
    var body: some View {
        List {
            Section {
                ForEach(history.reports) { report in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(report.day, format: .dateTime.month(.wide).day().year()).font(.headline)
                        Text("\(report.remaining) remaining · \(report.completedToday) completed · \(report.overdue) overdue")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("Observed \(report.recordedAt.formatted(.dateTime.locale(Locale(identifier: "en_US")).hour().minute()))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            } footer: { Text("Each report is the last snapshot recorded when the app was open that day. Days without observations are omitted.") }
        }.navigationTitle("Previous reports")
    }
}
