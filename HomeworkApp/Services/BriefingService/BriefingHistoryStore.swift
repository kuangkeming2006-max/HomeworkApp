import Foundation
import Observation
import HomeworkDomain

@Observable @MainActor
final class BriefingHistoryStore {
    private(set) var reports: [BriefingReport]
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reports = defaults.data(forKey: "briefingHistory.v1").flatMap { try? JSONDecoder().decode([BriefingReport].self, from: $0) } ?? []
    }

    func record(_ report: BriefingReport) {
        reports.removeAll { $0.day == report.day }
        reports.append(report); reports.sort { $0.day > $1.day }
        reports = Array(reports.prefix(31))
        if let data = try? JSONEncoder().encode(reports) { defaults.set(data, forKey: "briefingHistory.v1") }
    }
}
