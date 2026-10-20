import SwiftUI
import HomeworkDomain

struct ReminderPicker: View {
    @Binding var value: ReminderConfiguration
    @State private var custom = false

    var body: some View {
        Picker("Remind me", selection: Binding(
            get: { custom ? -1 : (ReminderConfiguration.presets.firstIndex(of: value) ?? -1) },
            set: { index in
                if index < 0 {
                    custom = true
                    if value.amount == 0 { value = .init(amount: 1, unit: .hours) }
                }
                else { custom = false; value = ReminderConfiguration.presets[index] }
            })) {
            ForEach(Array(ReminderConfiguration.presets.enumerated()), id: \.offset) { index, preset in
                Text(preset.label).tag(index)
            }
            Text("Custom").tag(-1)
        }
        .accessibilityIdentifier("reminder.preset")
        if custom || !ReminderConfiguration.presets.contains(value) {
            TextField("Amount", value: $value.amount, format: .number)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("reminder.amount")
            Picker("Unit", selection: $value.unit) {
                ForEach(ReminderConfiguration.Unit.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            .accessibilityIdentifier("reminder.unit")
            .onChange(of: value.unit) { _, unit in
                if unit == .weeks { value.amount = min(52, value.amount) }
            }
        }
    }
}
