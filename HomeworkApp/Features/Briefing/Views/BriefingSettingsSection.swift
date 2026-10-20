import SwiftUI
import HomeworkDomain

struct BriefingSettingsSection: View {
    let preferences: AppPreferences
    private var weekdayNames: [String] {
        var calendar = Calendar.current; calendar.locale = Locale(identifier: "en_US")
        return calendar.weekdaySymbols
    }
    private var time: Binding<Date> {
        Binding(get: {
            Calendar.current.date(from: DateComponents(hour: preferences.briefing.hour, minute: preferences.briefing.minute)) ?? .now
        }, set: {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
            var value = preferences.briefing; value.hour = parts.hour ?? 9; value.minute = parts.minute ?? 0
            preferences.briefing = value
        })
    }
    var body: some View {
        @Bindable var preferences = self.preferences
        Section {
            NativeToggleRow(title: "Scheduled reports", isOn: $preferences.briefing.enabled, identifier: "briefing.enabled")
            if preferences.briefing.enabled {
                Picker("Frequency", selection: $preferences.briefing.frequency) {
                    ForEach(BriefingConfiguration.Frequency.allCases) { Text($0.label).tag($0) }
                }.accessibilityIdentifier("briefing.frequency")
                DatePicker("Preferred time", selection: time, displayedComponents: .hourAndMinute)
                    .accessibilityIdentifier("briefing.time")
                if preferences.briefing.frequency == .weekly {
                    Picker("Day", selection: $preferences.briefing.weekday) {
                        ForEach(1...7, id: \.self) { Text(weekdayNames[$0 - 1]).tag($0) }
                    }
                }
            }
        } header: { Text("Briefing") }
          footer: { Text("Reports use your latest local data. Content may be out of date until you reopen the app. The next seven reports are scheduled when notifications are enabled.") }
    }
}
