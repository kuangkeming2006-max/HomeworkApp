import SwiftUI
import HomeworkDomain

struct CalendarView: View {
    let store: AssignmentStore
    @State private var model = CalendarViewModel()
    @State private var adding = false
    @State private var selectingMonth = false
    @State private var actionTarget: Assignment?
    @State private var statusDialog = false
    @Namespace private var selection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        TimelineView(.periodic(from: Date(timeIntervalSince1970: 0), by: 60)) { context in
          ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button("Previous month", systemImage: "chevron.left") { model.shiftMonth(-1) }
                        .labelStyle(.iconOnly).accessibilityIdentifier("calendar.previous")
                    Spacer()
                    Button { selectingMonth = true } label: {
                        HStack(spacing: 5) {
                            Text(model.month, format: .dateTime.month(.wide).year()).font(.title3.bold())
                            Image(systemName: "chevron.down").font(.caption)
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("calendar.month")
                    Spacer()
                    Button("Next month", systemImage: "chevron.right") { model.shiftMonth(1) }
                        .labelStyle(.iconOnly).accessibilityIdentifier("calendar.next")
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(model.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol).font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(Array(model.grid.days.enumerated()), id: \.offset) { _, day in
                        if let day { dayButton(day) }
                        else { Color.clear.frame(minHeight: 56).accessibilityHidden(true) }
                    }
                }
                .accessibilityIdentifier("calendar.grid")
                .id(model.month)
                .transition(.asymmetric(insertion: .move(edge: model.direction > 0 ? .trailing : .leading).combined(with: .opacity),
                                        removal: .move(edge: model.direction > 0 ? .leading : .trailing).combined(with: .opacity)))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 24).onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) * 1.5,
                       abs(value.predictedEndTranslation.width) > 60 { model.shiftMonth(value.translation.width < 0 ? 1 : -1) }
                })
                Divider()
                Text(model.selectedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.headline).accessibilityIdentifier("calendar.selectedDate")
                let values = model.index.day(model.selectedDate).assignments
                if values.isEmpty {
                    ContentUnavailableView("No assignments this day", systemImage: "calendar.badge.checkmark",
                                           description: Text("Add an assignment for the selected date."))
                        .frame(maxWidth: .infinity).accessibilityIdentifier("calendar.empty")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(values) { assignment in
                            HStack(alignment: .center, spacing: 12) {
                                Button { actionTarget = assignment; statusDialog = true } label: {
                                    Image(systemName: assignment.status == .abandoned ? "minus.circle.fill" : assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2).frame(minWidth: 32, minHeight: 44)
                                }
                                .accessibilityLabel("Change assignment status").accessibilityValue(assignment.status.label)
                                .accessibilityIdentifier("calendar.complete.\(assignment.id)")
                                NavigationLink {
                                    AssignmentDetailView(assignment: assignment, store: store)
                                } label: { AssignmentRow(assignment: assignment, now: context.date) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("calendar.open.\(assignment.id)")
                            }
                        }
                    }.id(model.selectedDate).transition(.opacity)
                }
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
          }
          .onChange(of: context.date, initial: true) { _, date in model.rebuild(store.assignments, now: date) }
          .onChange(of: store.assignments) { _, values in model.rebuild(values, now: context.date) }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: model.month)
        .animation(reduceMotion ? nil : .smooth(duration: 0.2), value: model.selectedDate)
        .navigationTitle("Calendar")
        .environment(\.calendar, model.calendar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Today") { model.today() }.accessibilityIdentifier("calendar.today")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add assignment", systemImage: "plus") { adding = true }
                    .accessibilityIdentifier("calendar.add")
            }
        }
        .sheet(isPresented: $adding) {
            NavigationStack { AssignmentDetailView(assignment: store.makeDraft(on: model.selectedDate),
                                                   isNew: true, store: store) }
        }
        .sheet(isPresented: $selectingMonth) {
            MonthYearPicker(calendar: model.calendar, selected: model.month) { model.selectMonth($0) }
        }
        .confirmationDialog("Assignment status", isPresented: $statusDialog, presenting: actionTarget) { task in
                if task.status == .active {
                    Button("Complete") { store.setStatus(task.id, to: .completed) }
                    Button("Abandon") { store.setStatus(task.id, to: .abandoned) }
                } else { Button("Restore") { store.setStatus(task.id, to: .active) } }
                Button("Cancel", role: .cancel) {}
        }
    }

    private func dayButton(_ day: Date) -> some View {
        let summary = model.index.day(day)
        let selected = model.calendar.isDate(day, inSameDayAs: model.selectedDate)
        return Button { model.selectedDate = day } label: {
            VStack(spacing: 4) {
                Text("\(model.calendar.component(.day, from: day))")
                    .fontWeight(selected ? .bold : .regular).monospacedDigit()
                HStack(spacing: 3) {
                    ForEach(summary.dots) { classification in
                        Circle().fill(classification.color).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 10)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                if selected { RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.15))
                    .matchedGeometryEffect(id: model.month, in: selection) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.month(.wide).day().year()))
        .accessibilityValue(summary.accessibilitySummary.isEmpty ? "No assignments" : summary.accessibilitySummary)
        .accessibilityIdentifier("calendar.day.\(model.identifier(for: day))")
    }
}
