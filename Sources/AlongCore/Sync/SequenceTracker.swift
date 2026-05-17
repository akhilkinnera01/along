import Foundation

public enum SequenceTrackerError: Error, Equatable, Sendable {
    case nonPositiveSequence(source: DeviceSurface, actual: Int64)
    case sequenceGap(source: DeviceSurface, expected: Int64, actual: Int64)
    case staleSequence(source: DeviceSurface, last: Int64, actual: Int64)
}

public struct SequenceTracker: Equatable, Sendable {
    private var lastSequenceBySource: [DeviceSurface: Int64]

    public init(lastSequenceBySource: [DeviceSurface: Int64] = [:]) {
        self.lastSequenceBySource = lastSequenceBySource
    }

    public func lastSequence(from source: DeviceSurface) -> Int64 {
        lastSequenceBySource[source] ?? 0
    }

    public func nextExpectedSequence(from source: DeviceSurface) -> Int64 {
        lastSequence(from: source) + 1
    }

    public mutating func record<Payload>(_ envelope: DeviceEnvelope<Payload>) throws
    where Payload: Codable & Equatable & Sendable {
        guard envelope.sequence > 0 else {
            throw SequenceTrackerError.nonPositiveSequence(source: envelope.source, actual: envelope.sequence)
        }

        let lastSequence = lastSequence(from: envelope.source)
        let expectedSequence = lastSequence + 1

        guard envelope.sequence == expectedSequence else {
            if envelope.sequence <= lastSequence {
                throw SequenceTrackerError.staleSequence(
                    source: envelope.source,
                    last: lastSequence,
                    actual: envelope.sequence
                )
            }

            throw SequenceTrackerError.sequenceGap(
                source: envelope.source,
                expected: expectedSequence,
                actual: envelope.sequence
            )
        }

        lastSequenceBySource[envelope.source] = envelope.sequence
    }
}
