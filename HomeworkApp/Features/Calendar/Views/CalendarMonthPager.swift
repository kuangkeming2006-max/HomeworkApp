import SwiftUI
import HomeworkDomain

/// Native date buttons share a horizontal-only pan with the containing scroll view.
struct CalendarMonthPager: View {
    let model: CalendarViewModel
    let onPickMonth: () -> Void
    let onPagingChanged: (Bool) -> Void
    let onNavigate: () -> Void
    @Environment(\.appReduceMotion) private var reduceMotion
    @Environment(\.appAccent) private var accent
    @State private var pages: [MonthPage] = []
    @State private var drag: CGFloat = 0
    @State private var width: CGFloat = 1
    @State private var settling = false
    @State private var generation = 0
    @State private var renderedMonth: Date?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private struct MonthPage: Identifiable {
        let id: Date
        let offset: Int
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
                                if let day { dayButton(day, page: page.id).id(day) }
                                else { Color.clear.frame(height: 48).accessibilityHidden(true) }
                            }
                        }
                        .frame(width: geometry.size.width)
                        .offset(x: CGFloat(page.offset) * geometry.size.width + drag)
                        .allowsHitTesting(page.offset == 0 && !settling)
                        .accessibilityHidden(page.offset != 0)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .clipped()
                .gesture(HorizontalCalendarPan(onBegin: {
                    generation += 1; settling = false; onPagingChanged(true)
                }, onChange: { distance in
                    drag = max(-geometry.size.width, min(geometry.size.width, distance))
                }, onEnd: { distance, velocity in
                    finish(distance: distance, velocity: velocity, width: geometry.size.width)
                }, onCancel: returnToRest))
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = max(1, $0) }
            }
            .frame(height: 318)
            .accessibilityIdentifier("calendar.grid")
        }
        .onChange(of: model.month, initial: true) { _, _ in
            guard renderedMonth != model.month else { return }
            generation += 1
            withTransaction(Transaction(animation: nil)) { rebuildPages(); drag = 0; settling = false }
            onPagingChanged(false)
        }
        .onDisappear {
            generation += 1; drag = 0; settling = false
        }
    }

    private func rebuildPages() {
        pages = (-1...1).map { offset in
            let date = model.calendar.date(byAdding: .month, value: offset, to: model.month) ?? model.month
            var days = MonthGrid(containing: date, calendar: model.calendar).days
            days += Array(repeating: nil, count: max(0, 42 - days.count))
            return MonthPage(id: date, offset: offset, days: days)
        }
        renderedMonth = model.month
    }

    private func shift(_ direction: Int, manual: Bool = false) {
        if !manual { onNavigate() }
        generation += 1
        let token = generation
        settling = true
        // Commit immediately and rebase the offset. Absolute month/day identities
        // preserve the incoming page instead of reusing a selected cell's old position.
        withTransaction(Transaction(animation: nil)) {
            model.shiftMonth(direction)
            rebuildPages()
            drag += CGFloat(direction) * width
        }
        withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.92), completionCriteria: .logicallyComplete) {
            drag = 0
        } completion: {
            guard generation == token else { return }
            settling = false
            if manual { onPagingChanged(false) }
        }
    }

    private func finish(distance: CGFloat, velocity: CGFloat, width: CGFloat) {
        let predicted = distance + velocity * 0.18
        if abs(distance) > width * 0.23 || abs(predicted) > width * 0.45 {
            let direction = abs(distance) > width * 0.23 ? distance : predicted
            shift(direction < 0 ? 1 : -1, manual: true)
        } else { returnToRest() }
    }

    private func returnToRest() {
        guard drag != 0 else { onPagingChanged(false); return }
        generation += 1
        let token = generation
        settling = true
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.9), completionCriteria: .logicallyComplete) {
            drag = 0
        } completion: {
            guard generation == token else { return }
            settling = false; onPagingChanged(false)
        }
    }

    private func dayButton(_ day: Date, page: Date) -> some View {
        let summary = model.index.day(day)
        let selected = page == model.month && model.calendar.isDate(day, inSameDayAs: model.selectedDate)
        return Button {
            guard !settling else { return }
            onNavigate()
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)) { model.selectDay(day) }
        } label: {
            VStack(spacing: 3) {
                Text("\(model.calendar.component(.day, from: day))")
                    .fontWeight(selected ? .bold : .regular).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                HStack(spacing: 3) {
                    ForEach(summary.dots) { classification in
                        Circle().fill(classification == .upcoming ? accent : classification.color).frame(width: 5, height: 5)
                    }
                }.frame(height: 8)
            }
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : Color.primary)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 8).fill(Color.primary).opacity(selected ? 1 : 0)
                    .transaction { $0.animation = nil }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityLabel(Text(day, format: .dateTime.month(.wide).day().year()))
        .accessibilityValue(summary.accessibilitySummary.isEmpty ? "No assignments" : summary.accessibilitySummary)
        .accessibilityIdentifier("calendar.day.\(model.identifier(for: day))")
    }
}
