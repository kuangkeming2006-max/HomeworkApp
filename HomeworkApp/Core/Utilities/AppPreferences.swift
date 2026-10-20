import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class AppPreferences {
    var defaultReminder: ReminderConfiguration {
        didSet {
            if let data = try? JSONEncoder().encode(defaultReminder) { defaults.set(data, forKey: "defaultReminder") }
            didChange?()
        }
    }
    private let defaults: UserDefaults
    var didChange: (@MainActor () -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "defaultReminder"),
           let saved = try? JSONDecoder().decode(ReminderConfiguration.self, from: data),
           (try? saved.validate()) != nil {
            defaultReminder = saved
        } else { defaultReminder = .none }
    }
}
