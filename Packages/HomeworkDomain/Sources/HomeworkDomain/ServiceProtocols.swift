import Foundation

@MainActor
public protocol AssignmentRepository {
    func fetchAll() throws -> [Assignment]
    func save(_ assignments: [Assignment]) throws
}

public protocol SyncService: Sendable {
    func synchronize() async throws
}

public struct OfflineSyncService: SyncService {
    public init() {}
    public func synchronize() async throws {}
}
