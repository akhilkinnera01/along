import Foundation

public struct DedupeWindow: Equatable, Sendable {
    public let capacity: Int
    private var orderedIDs: [UUID]
    private var seenIDs: Set<UUID>

    public init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.orderedIDs = []
        self.seenIDs = []
    }

    @discardableResult
    public mutating func record(_ id: UUID) -> Bool {
        guard !seenIDs.contains(id) else {
            return false
        }

        orderedIDs.append(id)
        seenIDs.insert(id)

        while orderedIDs.count > capacity {
            let removed = orderedIDs.removeFirst()
            seenIDs.remove(removed)
        }

        return true
    }

    public func contains(_ id: UUID) -> Bool {
        seenIDs.contains(id)
    }
}
