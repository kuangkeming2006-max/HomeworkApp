import SwiftUI

struct CalendarView: View {
    let store: AssignmentStore
    @State private var model = CalendarViewModel()
    @State private var adding = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button("Previous month", systemImage: "chevron.left") { model.shiftMonth(-1) }
                        .labelStyle(.iconOnly).accessibilityIdentifier("calendar.previous")
                    Spacer()
                    Text(model.month, format: .dateTime.month(.wide).year())
                        .font(.title3.bold()).accessibilityIdentifier("calendar.month")
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
                Divider()
                Text(model.selectedDate, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                    .font(.headline).accessibilityIdentifier("calendar.selectedDate")
                let values = model.assignments(on: model.selectedDate, in: store.assignments)
                if values.isEmpty {
                    ContentUnavailableView("No assignments this day", systemImage: "calendar.badge.checkmark",
                                           description: Text("Add an assignment for the selected date."))
                        .frame(maxWidth: .infinity).accessibilityIdentifier("calendar.empty")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(values) { assignment in
                            HStack(alignment: .top, spacing: 12) {
                                Button { store.toggleCompletion(assignment.id) } label: {
                                    Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                }
                                .accessibilityLabel(assignment.isCompleted ? "Mark incomplete" : "Complete assignment")
                                NavigationLink {
                                    AssignmentDetailView(assignment: assignment, store: store)
                                } label: { AssignmentRow(assignment: assignment) }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Calendar")
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
    }

    private func dayButton(_ day: Date) -> some View {
        let assignments = model.assignments(on: day, in: store.assignments)
        let pending = assignments.filter { !$0.isCompleted }.count
        let completed = assignments.count - pending
        let selected = model.calendar.isDate(day, inSameDayAs: model.selectedDate)
        return Button { model.selectedDate = day } label: {
            VStack(spacing: 4) {
                Text("\(model.calendar.component(.day, from: day))")
                    .fontWeight(selected ? .bold : .regular).monospacedDigit()
                HStack(spacing: 3) {
                    if pending > 0 { Circle().fill(.tint).frame(width: 5, height: 5) }
                    if completed > 0 { Circle().fill(.secondary).frame(width: 5, height: 5) }
                    if assignments.count > 2 { Text("\(assignments.count)").font(.caption2) }
                }
                .frame(height: 10)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(selected ? Color.accentColor.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day, format: .dateTime.month(.wide).day().year()))
        .accessibilityValue("\(pending) upcoming, \(completed) completed")
        .accessibilityIdentifier("calendar.day.\(model.identifier(for: day))")
    }
}
