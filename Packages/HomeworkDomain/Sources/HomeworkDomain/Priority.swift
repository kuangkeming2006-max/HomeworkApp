public enum Priority: Int, Codable, CaseIterable, Identifiable, Sendable {
    case urgent = 1
    case high = 2
    case medium = 3
    case low = 4

    public var id: Int { rawValue }
    public var label: String {
        switch self {
        case .urgent: "P1 · Urgent"
        case .high: "P2 · High"
        case .medium: "P3 · Medium"
        case .low: "P4 · Low"
        }
    }
}
