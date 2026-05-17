import Foundation

public struct MissionEvent: Codable, Equatable, Sendable {
    public let id: MissionEventID
    public let missionID: MissionID
    public let sequence: Int
    public let kind: MissionEventKind
    public let occurredAt: Date

    public init(
        id: MissionEventID,
        missionID: MissionID,
        sequence: Int,
        kind: MissionEventKind,
        occurredAt: Date
    ) {
        self.id = id
        self.missionID = missionID
        self.sequence = sequence
        self.kind = kind
        self.occurredAt = occurredAt
    }
}

public enum MissionEventKind: Codable, Equatable, Sendable {
    case missionStarted(template: MissionTemplateKind, title: String)
    case statusChanged(MissionStatus)
    case summaryChanged(String)
    case approvalRequested(ApprovalID, String)
    case approvalResolved(ApprovalID, Bool)
    case agentTurnStarted(String)
    case agentTurnCompleted(String)
    case agentTurnFailed(RuntimeFailure)
    case toolStarted(String)
    case toolCompleted(String)
    case toolFailed(String, RuntimeFailure)
}
