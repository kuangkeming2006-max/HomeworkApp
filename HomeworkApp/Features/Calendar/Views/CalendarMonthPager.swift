import SwiftUI
import HomeworkDomain

/// One touch recognizer owns the entire grid, so day activation cannot compete with paging.
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
    @GestureState private var activeTouchID: UUID? = nil
    @State private var tracking: GridTouch?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private struct MonthPage: Identifiable {
        let id: Date
        let offset: Int
        let days: [Date?]
    }

    private enum TouchAxis { case undecided, horizontal, vertical }
    private struct GridTouch {
        let id: UUID?
        let start: CGPoint
        var greatestDistance: CGFloat = 0
        var axis: TouchAxis = .undecided
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
                // Simultaneous recognition leaves vertical scrolling to the containing ScrollView.
                .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .updating($activeTouchID) { _, identifier, _ in
                        if identifier == nil { identifier = UUID() }
                    }
                    .onChanged { track($0, width: geometry.size.width) }
                    .onEnded { finish($0, width: geometry.size.width) })
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
        .onChange(of: activeTouchID) { _, identifier in
            // GestureState also resets on cancellation, where onEnded is not called.
            guard identifier == nil else { return }
            let endedTouch = tracking?.id
            Task { @MainActor in
                // Allow the normal onEnded callback to commit before handling cancellation.
                await Task.yield()
                guard activeTouchID == nil, tracking?.id == endedTouch, !settling, drag != 0 else { return }
                tracking = nil
                returnToRest()
            }
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

    private func track(_ value: DragGesture.Value, width: CGFloat) {
        var touch = tracking?.id == activeTouchID ? tracking : nil
        if touch == nil { touch = GridTouch(id: activeTouchID, start: value.startLocation) }
        guard var touch else { return }
        let x = abs(value.translation.width)
        let y = abs(value.translation.height)
        touch.greatestDistance = max(touch.greatestDistance, hypot(x, y))
        if touch.axis == .undecided, max(x, y) > 8 {
            if x > y * 1.2 {
                touch.axis = .horizontal
                generation += 1; settling = false
                onPagingChanged(true)
            }
            else if y > x * 1.2 { touch.axis = .vertical }
        }
        tracking = touch
        if touch.axis == .horizontal { drag = max(-width, min(width, value.translation.width)) }
    }

    private func finish(_ value: DragGesture.Value, width: CGFloat) {
        defer { tracking = nil }
        guard !settling, let touch = tracking else { return }
        if touch.axis == .horizontal {
            let distance = value.translation.width
            if abs(distance) > width * 0.23 || abs(value.predictedEndTranslation.width) > width * 0.45 {
                shift(distance < 0 ? 1 : -1, manual: true)
            } else { returnToRest() }
        } else if touch.greatestDistance <= 8,
                  let startDay = day(at: touch.start, width: width),
                  let endDay = day(at: value.location, width: width),
                  model.calendar.isDate(startDay, inSameDayAs: endDay) {
            onNavigate()
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)) { model.selectDay(endDay) }
        }
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

    private func day(at point: CGPoint, width: CGFloat) -> Date? {
        let cellWidth = (width - 24) / 7
        guard cellWidth > 0, point.x >= 0, point.y >= 0, point.x < width, point.y < 318 else { return nil }
        let column = Int(point.x / (cellWidth + 4))
        let row = Int(point.y / 54)
        let rectangle = CGRect(x: CGFloat(column) * (cellWidth + 4), y: CGFloat(row) * 54, width: cellWidth, height: 48)
        let index = row * 7 + column
        guard column < 7, rectangle.contains(point), let page = pages.first(where: { $0.offset == 0 }), page.days.indices.contains(index) else { return nil }
        return page.days[index]
    }

    private func dayButton(_ day: Date, page: Date) -> some View {
        let summary = model.index.day(day)
        let selected = page == model.month && model.calendar.isDate(day, inSameDayAs: model.selectedDate)
        return VStack(spacing: 3) {
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
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityAction {
            guard !settling else { return }
            onNavigate()
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9)) { model.selectDay(day) }
        }
        .accessibilityLabel(Text(day, format: .dateTime.month(.wide).day().year()))
        .accessibilityValue(summary.accessibilitySummary.isEmpty ? "No assignments" : summary.accessibilitySummary)
        .accessibilityIdentifier("calendar.day.\(model.identifier(for: day))")
    }
}
