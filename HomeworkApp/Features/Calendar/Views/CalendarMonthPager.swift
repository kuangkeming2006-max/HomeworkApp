import SwiftUI
import HomeworkDomain

/// Three cached month grids move as one strip. Date taps are suppressed once a drag starts.
struct CalendarMonthPager: View {
    let model: CalendarViewModel
    let onPickMonth: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pages: [MonthPage] = []
    @State private var drag: CGFloat = 0
    @State private var width: CGFloat = 1
    @State private var settling = false
    @State private var horizontalDrag = false
    @State private var acceptTapsAfter = Date.distantPast
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private struct MonthPage: Identifiable {
        let id: Int
        let days: [Date?]
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button("Previous month", systemImage: "chevron.left") { shift(-1) }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("calendar.previous")
                Spacer(minLength: 0)
                Button(action: onPickMonth) {
                    HStack(spacing: 5) {
                        Text(model.month, format: .dateTime.month(.wide).year()).font(.title3.bold())
                            .lineLimit(2).multilineTextAlignment(.center)
                        Image(systemName: "chevron.down").font(.caption)
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("calendar.month")
                Spacer(minLength: 0)
                Button("Next month", systemImage: "chevron.right") { shift(1) }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("calendar.next")
            }
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(model.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.5)
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    ForEach(pages) { page in
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(Array(page.days.enumerated()), id: \.offset) { _, day in
                                if let day { dayButton(day) }
                                else { Color.clear.frame(height: 48).accessibilityHidden(true) }
                            }
                        }
                        .frame(width: geometry.size.width)
                        .offset(x: CGFloat(page.id) * geometry.size.width + drag)
                        .allowsHitTesting(page.id == 0 && !settling)
                        .accessibilityHidden(page.id != 0)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .clipped()
                .simultaneousGesture(DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !settling else { return }
                        if !horizontalDrag {
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            horizontalDrag = true
                        }
                        acceptTapsAfter = Date().addingTimeInterval(0.3)
                        drag = max(-geometry.size.width, min(geometry.size.width, value.translation.width))
                    }
                    .onEnded { value in
                        guard horizontalDrag, !settling else { return }
                        horizontalDrag = false
                        acceptTapsAfter = Date().addingTimeInterval(0.3)
                        if abs(drag) > geometry.size.width * 0.23 || abs(value.predictedEndTranslation.width) > geometry.size.width * 0.45 {
                            shift(drag < 0 ? 1 : -1)
                        } else {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.9)) { drag = 0 }
                        }
                    })
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = max(1, $0) }
            }
            .frame(height: 318)
            .accessibilityIdentifier("calendar.grid")
        }
        .onChange(of: model.month, initial: true) { _, _ in rebuildPages() }
    }

    private func rebuildPages() {
        pages = (-1...1).map { offset in
            let date = model.calendar.date(byAdding: .month, value: offset, to: model.month) ?? model.month
            var days = MonthGrid(containing: date, calendar: model.calendar).days
            days += Array(repeating: nil, count: max(0, 42 - days.count))
            return MonthPage(id: offset, days: days)
        }
    }

    private func shift(_ direction: Int) {
        guard !settling else { return }
        settling = true
        acceptTapsAfter = Date().addingTimeInterval(0.5)
        withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.92), completionCriteria: .logicallyComplete) {
            drag = -CGFloat(direction) * width
        } completion: {
            withTransaction(Transaction(animation: nil)) {
                model.shiftMonth(direction)
                rebuildPages()
                drag = 0
                settling = false
            }
        }
    }

    private func dayButton(_ day: Date) -> some View {
        let summary = model.index.day(day)
        let selected = model.calendar.isDate(day, inSameDayAs: model.selectedDate)
        return Button {
            guard !settling, !horizontalDrag, Date() >= acceptTapsAfter else { return }
            model.selectedDate = day
        } label: {
            VStack(spacing: 3) {
                Text("\(model.calendar.component(.day, from: day))")
                    .fontWeight(selected ? .bold : .regular).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                HStack(spacing: 3) {
                    ForEach(summary.dots) { classification in Circle().fill(classification.color).frame(width: 5, height: 5) }
                }.frame(height: 8)
            }
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 8).fill(Color.primary).opacity(selected ? 1 : 0)
            }
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.month(.wide).day().year()))
        .accessibilityValue(summary.accessibilitySummary.isEmpty ? "No assignments" : summary.accessibilitySummary)
        .accessibilityIdentifier("calendar.day.\(model.identifier(for: day))")
    }
}
