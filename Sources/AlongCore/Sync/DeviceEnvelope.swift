import Foundation

public enum DeviceSurface: String, Codable, CaseIterable, Equatable, Sendable {
    case phone
    case watch
    case relay
}

public enum DeviceEnvelopeKind: String, Codable, CaseIterable, Equatable, Sendable {
    case missionEvent
    case missionSnapshot
    case approvalResponse
    case presence
    case acknowledgement
}

public struct DeviceEnvelope<Payload>: Codable, Equatable, Sendable
where Payload: Codable & Equatable & Sendable {
    public let id: UUID
    public let source: DeviceSurface
    public let missionID: MissionID?
    public let sequence: Int64
    public let kind: DeviceEnvelopeKind
    public let payload: Payload
    public let createdAt: Date

    public init(
        id: UUID,
        source: DeviceSurface,
        missionID: MissionID?,
        sequence: Int64,
        kind: DeviceEnvelopeKind,
        payload: Payload,
        createdAt: Date
    ) {
        self.id = id
        self.source = source
        self.missionID = missionID
        self.sequence = sequence
        self.kind = kind
        self.payload = payload
        self.createdAt = createdAt
    }
}

public struct DeviceSyncAcknowledgement: Codable, Equatable, Sendable {
    public let envelopeID: UUID
    public let source: DeviceSurface
    public let receivedSequence: Int64
    public let createdAt: Date

    public init(
        envelopeID: UUID,
        source: DeviceSurface,
        receivedSequence: Int64,
        createdAt: Date
    ) {
        self.envelopeID = envelopeID
        self.source = source
        self.receivedSequence = receivedSequence
        self.createdAt = createdAt
    }
}
