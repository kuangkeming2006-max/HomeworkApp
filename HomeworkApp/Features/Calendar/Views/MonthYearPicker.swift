import SwiftUI

struct MonthYearPicker: View {
    let calendar: Calendar
    let selected: Date
    let select: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var year: Int
    @State private var month: Int

    init(calendar: Calendar, selected: Date, select: @escaping (Date) -> Void) {
        self.calendar = calendar; self.selected = selected; self.select = select
        _year = State(initialValue: calendar.component(.year, from: selected))
        _month = State(initialValue: calendar.component(.month, from: selected))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Year", selection: $year) {
                    ForEach((min(1900, year - 100))...(max(2200, year + 100)), id: \.self) { Text(String($0)).tag($0) }
                }.accessibilityIdentifier("calendar.yearPicker")
                Picker("Month", selection: $month) {
                    ForEach(1...12, id: \.self) { Text(calendar.monthSymbols[$0 - 1]).tag($0) }
                }.accessibilityIdentifier("calendar.monthPicker")
            }
            .navigationTitle("Month and year").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Go") {
                        if let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) { select(date) }
                        dismiss()
                    }.accessibilityIdentifier("calendar.go")
                }
            }
        }.presentationDetents([.medium, .large])
    }
}
